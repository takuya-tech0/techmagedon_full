# main.py - Full code with splitted endpoints and methods

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Optional
from pydantic import BaseModel
from datetime import datetime
import mysql.connector
from mysql.connector import Error
from mysql.connector.cursor import MySQLCursor
import os
from functools import lru_cache
import openai
import dotenv
import logging
import asyncio

# Load environment variables
dotenv.load_dotenv()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class Settings:
    def __init__(self):
        self.MYSQL_HOST = os.getenv('MYSQL_HOST', 'tech0-db-step4-studentrdb-3.mysql.database.azure.com')
        self.MYSQL_USER = os.getenv('MYSQL_USER', 'tech0gen7student')
        self.MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', 'vY7JZNfU')
        self.MYSQL_DATABASE = os.getenv('MYSQL_DATABASE', 'techmagedon')
        self.SSL_CA = os.getenv('SSL_CA', 'DigiCertGlobalRootCA.crt.pem')
        self.OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')

    @property
    def DB_CONFIG(self):
        config = {
            'host': self.MYSQL_HOST,
            'user': self.MYSQL_USER,
            'password': self.MYSQL_PASSWORD,
            'database': self.MYSQL_DATABASE,
            'charset': 'utf8mb4',
            'collation': 'utf8mb4_unicode_ci',
            'use_unicode': True
        }

        if os.path.exists(self.SSL_CA):
            config.update({
                'client_flags': [mysql.connector.ClientFlag.SSL],
                'ssl_ca': self.SSL_CA
            })
        else:
            logger.warning(f"Warning: SSL certificate file not found at {self.SSL_CA}")
            if self.MYSQL_HOST == 'localhost' or self.MYSQL_HOST.startswith('127.0.0.1'):
                pass
            else:
                raise FileNotFoundError(f"SSL certificate required but not found: {self.SSL_CA}")

        return config

@lru_cache()
def get_settings():
    return Settings()

class MaterialResponse(BaseModel):
    material_id: int
    unit_id: int
    title: Optional[str] = None
    description: Optional[str] = None
    material_type: Optional[str] = None
    blob_url: Optional[str] = None
    blob_name: Optional[str] = None
    file_size: Optional[int] = None
    duration: Optional[int] = None
    page_count: Optional[int] = None
    created_at: datetime
    updated_at: datetime

class LessonUnit(BaseModel):
    unit_id: int
    field_id: int
    name: Optional[str] = None
    order_num: Optional[int] = None
    created_at: datetime

class Message(BaseModel):
    message_id: int
    conversation_id: int
    content: Optional[str] = None
    role: Optional[str] = None
    created_at: datetime

class ChatConversation(BaseModel):
    conversation_id: int
    user_id: int
    unit_id: int
    title: Optional[str] = None
    summary: Optional[str] = None
    understanding_flag: Optional[bool] = None
    created_at: datetime
    updated_at: datetime
    is_public: Optional[bool] = None
    view_count: Optional[int] = None
    like_count: Optional[int] = None
    bookmark_count: Optional[int] = None
    is_pinned: Optional[bool] = None
    is_to_teacher: Optional[bool] = None
    teacher_response_type: Optional[str] = None
    teacher_response_status: Optional[str] = None

class ConversationDetail(BaseModel):
    conversation: ChatConversation
    messages: List[Message]

class ConversationCreateRequest(BaseModel):
    user_id: int
    unit_id: int

class MessageCreateRequest(BaseModel):
    conversation_id: int
    content: str
    role: str
    is_first_message: bool = False

import mysql.connector
from mysql.connector import Error
from mysql.connector.cursor import MySQLCursor
from contextlib import asynccontextmanager

class MySQLManager:
    def __init__(self, config):
        self.config = config
        self._connection = None
        self._cursor = None
        self._lock = asyncio.Lock()

    async def __aenter__(self):
        await self.connect()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.disconnect()

    async def connect(self):
        try:
            async with self._lock:
                if not self._connection or not self._connection.is_connected():
                    self._connection = mysql.connector.connect(**self.config)
                    self._cursor = self._connection.cursor(dictionary=True, buffered=True)
                    self._cursor.execute('SET NAMES utf8mb4')
                    self._cursor.execute('SET CHARACTER SET utf8mb4')
                    self._cursor.execute('SET character_set_connection=utf8mb4')
                    logger.info("Connected to MySQL database")
        except Error as e:
            logger.error(f"Error connecting to MySQL: {e}")
            raise

    async def disconnect(self):
        async with self._lock:
            if self._cursor:
                self._cursor.close()
            if self._connection and self._connection.is_connected():
                self._connection.close()
                logger.info("Disconnected from MySQL database")

    async def execute_query(self, query: str, params: tuple = None) -> MySQLCursor:
        try:
            async with self._lock:
                self._cursor.execute(query, params)
                return self._cursor
        except Error as e:
            logger.error(f"Error executing query: {e}")
            raise

    async def start_transaction(self):
        try:
            async with self._lock:
                self._connection.start_transaction()
                logger.info("Started new transaction")
        except Error as e:
            logger.error(f"Error starting transaction: {e}")
            raise

    async def commit(self):
        try:
            async with self._lock:
                self._connection.commit()
                logger.info("Committed transaction")
        except Error as e:
            logger.error(f"Error committing transaction: {e}")
            raise

    async def rollback(self):
        try:
            async with self._lock:
                self._connection.rollback()
                logger.info("Rolled back transaction")
        except Error as e:
            logger.error(f"Error rolling back transaction: {e}")
            raise

class MaterialsDB:
    def __init__(self, settings: Settings):
        self.settings = settings
        if not self.settings.OPENAI_API_KEY:
            logger.error("OpenAI API Key is not set")
            raise ValueError("OpenAI API Key is required")
        openai.api_key = self.settings.OPENAI_API_KEY

    async def get_materials_by_unit(self, unit_id: int) -> Dict:
        query = """
        SELECT material_id, unit_id, title, description, material_type,
               blob_url, blob_name, file_size, duration, page_count, 
               created_at, updated_at
        FROM lesson_materials 
        WHERE unit_id = %s
        ORDER BY 
            CASE
                WHEN material_type = 'video' THEN 0
                ELSE 1
            END,
            created_at ASC
        """
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = await db.execute_query(query, (unit_id,))
            results = cursor.fetchall()
            if not results:
                logger.info(f"No materials found for unit_id={unit_id}")
                raise HTTPException(status_code=404, detail="Materials not found for this unit")
            
            materials = {
                'video': None,
                'pdfs': []
            }
            for result in results:
                if result['material_type'] == 'video':
                    materials['video'] = MaterialResponse(**result)
                else:
                    materials['pdfs'].append(MaterialResponse(**result))
            return materials

    async def get_material_by_id(self, material_id: int) -> MaterialResponse:
        query = """
        SELECT material_id, unit_id, title, description, material_type,
               blob_url, blob_name, file_size, duration, page_count, 
               created_at, updated_at
        FROM lesson_materials 
        WHERE material_id = %s
        """
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = await db.execute_query(query, (material_id,))
            result = cursor.fetchone()
            if not result:
                logger.info(f"Material not found: material_id={material_id}")
                raise HTTPException(status_code=404, detail="Material not found")
            return MaterialResponse(**result)

    async def get_default_unit_materials(self) -> Dict:
        return await self.get_materials_by_unit(1)

    async def get_current_unit(self, unit_id: int) -> LessonUnit:
        query = """
        SELECT unit_id, field_id, name, order_num, created_at
        FROM units 
        WHERE unit_id = %s
        """
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = await db.execute_query(query, (unit_id,))
            result = cursor.fetchone()
            if not result:
                logger.info(f"Unit not found: unit_id={unit_id}")
                raise HTTPException(status_code=404, detail="Unit not found")
            return LessonUnit(**result)

    async def get_chat_history(self) -> List[ChatConversation]:
        query = """
        SELECT * FROM ai_conversations 
        ORDER BY updated_at DESC
        """
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = await db.execute_query(query)
            results = cursor.fetchall()
            if not results:
                logger.info("No chat history found.")
                return []
            try:
                chat_conversations = []
                for result in results:
                    try:
                        chat_conversations.append(ChatConversation(**result))
                    except Exception as e:
                        conversation_id = result.get('conversation_id', 'Unknown')
                        logger.error(f"Error parsing conversation_id={conversation_id}: {e}")
                return chat_conversations
            except Exception as e:
                logger.error(f"Error parsing chat history: {e}")
                raise HTTPException(status_code=500, detail="Error fetching chat history")

    async def get_conversation_detail(self, conversation_id: int) -> ConversationDetail:
        conversation_query = """
        SELECT * FROM ai_conversations 
        WHERE conversation_id = %s
        """
        messages_query = """
        SELECT * FROM messages 
        WHERE conversation_id = %s 
        ORDER BY created_at ASC
        """
        
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = await db.execute_query(conversation_query, (conversation_id,))
            conversation_result = cursor.fetchone()
            if not conversation_result:
                logger.info(f"Conversation not found: conversation_id={conversation_id}")
                raise HTTPException(status_code=404, detail="Conversation not found")
            
            cursor = await db.execute_query(messages_query, (conversation_id,))
            messages_result = cursor.fetchall()
            
            return ConversationDetail(
                conversation=ChatConversation(**conversation_result),
                messages=[Message(**msg) for msg in messages_result]
            )

    async def create_conversation(self, user_id: int, unit_id: int) -> int:
        query = """
        INSERT INTO ai_conversations (
            user_id, unit_id, title, summary,
            understanding_flag, created_at, updated_at,
            is_public, view_count, like_count,
            bookmark_count, is_pinned, is_to_teacher,
            teacher_response_type, teacher_response_status
        )
        VALUES (
            %s, %s, %s, %s,
            %s, NOW(), NOW(),
            %s, %s, %s,
            %s, %s, %s,
            %s, %s
        )
        """
        default_title = '無題の会話'
        default_values = (
            user_id,
            unit_id,
            default_title,
            'summary',
            False,          # understanding_flag
            False,          # is_public
            0,              # view_count
            0,              # like_count
            0,              # bookmark_count
            False,          # is_pinned
            False,          # is_to_teacher
            'chat',         # teacher_response_type
            'waiting'       # teacher_response_status
        )

        async with MySQLManager(self.settings.DB_CONFIG) as db:
            try:
                await db.start_transaction()
                cursor = await db.execute_query(query, default_values)
                conversation_id = cursor.lastrowid
                await db.commit()
                logger.info(f"Created new conversation: conversation_id={conversation_id}")
                return conversation_id
            except Exception as e:
                await db.rollback()
                logger.error(f"Error creating conversation: {e}")
                raise HTTPException(status_code=500, detail=f"Failed to create conversation: {str(e)}")

    # 新規追加メソッド群(分割対応)
    async def add_user_message(self, conversation_id: Optional[int], content: str, user_id: int = 1, unit_id: int = 1) -> int:
        """
        ユーザーメッセージをDBに追加する。
        conversation_idがNoneなら新規にconversationを作成。
        戻り値として使用したconversation_idを返す。
        """
        if conversation_id is None:
            # 新規会話作成
            conversation_id = await self.create_conversation(user_id, unit_id)

        async with MySQLManager(self.settings.DB_CONFIG) as db:
            try:
                await db.start_transaction()
                message_query = """
                INSERT INTO messages (conversation_id, content, role, created_at)
                VALUES (%s, %s, 'user', NOW())
                """
                await db.execute_query(message_query, (conversation_id, content))

                # 会話の更新日時をアップデート
                update_query = """
                UPDATE ai_conversations
                SET updated_at = NOW()
                WHERE conversation_id = %s
                """
                await db.execute_query(update_query, (conversation_id,))

                await db.commit()

                logger.info(f"User message added to conversation_id={conversation_id}")
                return conversation_id
            except Exception as e:
                await db.rollback()
                logger.error(f"Error adding user message: {e}")
                raise HTTPException(status_code=500, detail="Failed to add user message")

    async def generate_assistant_response(self, conversation_id: int) -> str:
        """
        アシスタントメッセージを生成してDBに保存して返す
        """
        # ユーザーメッセージ履歴を取得
        messages = await self._get_all_messages_for_conversation(conversation_id)
        user_messages = [m for m in messages if m['role'] == 'user']

        if not user_messages:
            raise HTTPException(status_code=400, detail="No user messages in this conversation")

        # チャット履歴をOpenAIに送信
        assistant_message = await self._query_openai_for_assistant(user_messages)

        # 生成されたアシスタントメッセージをDBに保存
        await self._add_assistant_message(conversation_id, assistant_message)

        return assistant_message

    async def generate_conversation_title(self, conversation_id: int) -> str:
        """
        タイトルを生成して更新する
        """
        messages = await self._get_all_messages_for_conversation(conversation_id)
        title = await self._generate_title_from_messages(conversation_id, messages)
        # タイトル更新
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            try:
                await db.start_transaction()
                update_title_query = """
                UPDATE ai_conversations SET title = %s, updated_at=NOW() WHERE conversation_id = %s
                """
                await db.execute_query(update_title_query, (title, conversation_id))
                await db.commit()
            except Exception as e:
                await db.rollback()
                logger.error(f"Error updating title: {e}")
                raise HTTPException(status_code=500, detail="Failed to update title")

        return title

    async def _get_all_messages_for_conversation(self, conversation_id: int) -> List[Dict]:
        query = """
        SELECT message_id, conversation_id, content, role, created_at
        FROM messages 
        WHERE conversation_id = %s
        ORDER BY created_at ASC
        """
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = await db.execute_query(query, (conversation_id,))
            return cursor.fetchall()

    async def _query_openai_for_assistant(self, user_messages: List[Dict]) -> str:
        """
        最新のユーザーメッセージ内容に基づいてアシスタントメッセージを生成
        """
        # ユーザーメッセージをOpenAI用フォーマットに変換
        # システムメッセージを1つ追加
        messages_for_openai = [{"role": "system", "content": "あなたは高校1年生の物理を教える教師アシスタントです。わかりやすく、丁寧に説明してください。"}]
        for msg in user_messages:
            messages_for_openai.append({"role": "user", "content": msg['content']})

        try:
            response = await openai.ChatCompletion.acreate(
                model="gpt-3.5-turbo",
                messages=messages_for_openai,
                max_tokens=150,
                temperature=0.7,
            )
            assistant_message = response['choices'][0]['message']['content'].strip()
            return assistant_message
        except openai.error.OpenAIError as e:
            logger.error(f"OpenAI API Error: {e}")
            raise HTTPException(status_code=500, detail="Error generating AI response")
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise HTTPException(status_code=500, detail="Unexpected error")

    async def _add_assistant_message(self, conversation_id: int, content: str):
        """
        アシスタントメッセージをDBに追加
        """
        async with MySQLManager(self.settings.DB_CONFIG) as db:
            try:
                await db.start_transaction()
                message_query = """
                INSERT INTO messages (conversation_id, content, role, created_at)
                VALUES (%s, %s, 'assistant', NOW())
                """
                await db.execute_query(message_query, (conversation_id, content))

                # 会話の更新日時をアップデート
                update_query = """
                UPDATE ai_conversations
                SET updated_at = NOW()
                WHERE conversation_id = %s
                """
                await db.execute_query(update_query, (conversation_id,))

                await db.commit()
            except Exception as e:
                await db.rollback()
                logger.error(f"Error adding assistant message: {e}")
                raise HTTPException(status_code=500, detail="Failed to add assistant message")

    async def _generate_title_from_messages(self, conversation_id: int, messages: List[Dict]) -> str:
        user_messages = [m for m in messages if m['role'] == 'user']
        if not user_messages:
            return "無題の会話"

        try:
            prompt_messages = [
                {"role": "system", "content": "以下の会話内容に基づいて、簡潔なタイトルを生成してください。"}
            ] + [{"role": "user", "content": msg['content']} for msg in user_messages]

            response = await openai.ChatCompletion.acreate(
                model="gpt-3.5-turbo",
                messages=prompt_messages,
                max_tokens=10,
                temperature=0.7,
            )
            title = response['choices'][0]['message']['content'].strip()
            logger.info(f"Generated title for conversation {conversation_id}: {title}")
            return title or "無題の会話"
        except Exception as e:
            logger.error(f"Error generating title: {e}")
            return "無題の会話"


app = FastAPI(
    title="Techmagedon API",
    description="高校物理学習支援アプリケーションのバックエンドAPI",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db(settings: Settings = Depends(get_settings)):
    return MaterialsDB(settings)


# ---- Materials and Units endpoints (unchanged) ----
@app.get("/materials/unit/{unit_id}", response_model=Dict)
async def get_materials_by_unit(
    unit_id: int,
    db: MaterialsDB = Depends(get_db)
):
    try:
        return await db.get_materials_by_unit(unit_id)
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error fetching materials: {e}")
        raise HTTPException(status_code=500, detail="Unexpected error fetching materials")

@app.get("/materials/{material_id}", response_model=MaterialResponse)
async def get_material(
    material_id: int,
    db: MaterialsDB = Depends(get_db)
):
    try:
        return await db.get_material_by_id(material_id)
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error fetching material: {e}")
        raise HTTPException(status_code=500, detail="Unexpected error fetching material")

@app.get("/materials/default", response_model=Dict)
async def get_default_materials(
    db: MaterialsDB = Depends(get_db)
):
    try:
        return await db.get_default_unit_materials()
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error fetching default materials: {e}")
        raise HTTPException(status_code=500, detail="Unexpected error fetching default materials")

@app.get("/units/{unit_id}", response_model=LessonUnit)
async def get_unit(
    unit_id: int,
    db: MaterialsDB = Depends(get_db)
):
    try:
        return await db.get_current_unit(unit_id)
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error fetching unit: {e}")
        raise HTTPException(status_code=500, detail="Unexpected error fetching unit")

# ---- Chat endpoints ----

@app.get("/chat/history", response_model=List[ChatConversation])
async def get_chat_history(
    db: MaterialsDB = Depends(get_db)
):
    try:
        return await db.get_chat_history()
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error fetching chat history: {e}")
        raise HTTPException(status_code=500, detail="Unexpected error fetching chat history")

@app.get("/chat/{conversation_id}", response_model=ConversationDetail)
async def get_conversation_detail(
    conversation_id: int,
    db: MaterialsDB = Depends(get_db)
):
    try:
        return await db.get_conversation_detail(conversation_id)
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error fetching conversation detail: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected error fetching conversation detail: {str(e)}"
        )

@app.post("/chat/conversations", response_model=Dict)
async def create_conversation(
    request: ConversationCreateRequest,
    db: MaterialsDB = Depends(get_db)
):
    try:
        conversation_id = await db.create_conversation(request.user_id, request.unit_id)
        return {"conversation_id": conversation_id}
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error creating conversation: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create conversation: {str(e)}")

# ユーザーメッセージを送るだけのエンドポイント
@app.post("/chat/messages", response_model=Dict)
async def add_user_message_endpoint(
    request: MessageCreateRequest,
    db: MaterialsDB = Depends(get_db)
):
    """
    ユーザーメッセージをDBに保存するだけ。
    AIの応答やタイトル生成は行わない。
    """
    try:
        conv_id = request.conversation_id if request.conversation_id != 0 else None
        used_conversation_id = await db.add_user_message(conv_id, request.content, user_id=1, unit_id=1)
        return {"status": "user_message_stored", "conversation_id": used_conversation_id}
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Error adding user message: {e}")
        raise HTTPException(status_code=500, detail="Failed to add user message")

# アシスタントメッセージ生成専用エンドポイント
@app.post("/chat/conversations/{conversation_id}/assistant_response", response_model=Dict)
async def assistant_response_endpoint(
    conversation_id: int,
    db: MaterialsDB = Depends(get_db)
):
    """
    アシスタントメッセージ生成・保存を行う
    """
    try:
        assistant_msg = await db.generate_assistant_response(conversation_id)
        return {"assistant_message": assistant_msg}
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Error generating assistant response: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate assistant response")

# タイトル生成専用エンドポイント
@app.post("/chat/conversations/{conversation_id}/title", response_model=Dict)
async def generate_title_endpoint(
    conversation_id: int,
    db: MaterialsDB = Depends(get_db)
):
    """
    会話タイトルを生成・更新して返す
    """
    try:
        title = await db.generate_conversation_title(conversation_id)
        return {"status": "title_generated", "title": title}
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Error generating title: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate title")

@app.get("/health")
async def health_check():
    """APIの健康状態を確認"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    }

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up Techmagedon API")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down Techmagedon API")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info",
        reload=True
    )