# main.py

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

# Load environment variables
dotenv.load_dotenv()

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Config model
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

# Response Models
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

# Request Models
class ConversationCreateRequest(BaseModel):
    user_id: int
    unit_id: int

class MessageCreateRequest(BaseModel):
    conversation_id: int
    content: str
    role: str  # 'user' or 'assistant'

# MySQL Connection Manager
class MySQLManager:
    def __init__(self, config):
        self.config = config
        self._connection = None
        self._cursor = None

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.disconnect()

    def connect(self):
        try:
            if not self._connection or not self._connection.is_connected():
                self._connection = mysql.connector.connect(**self.config)
                self._cursor = self._connection.cursor(dictionary=True, buffered=True)
                self._cursor.execute('SET NAMES utf8mb4')
                self._cursor.execute('SET CHARACTER SET utf8mb4')
                self._cursor.execute('SET character_set_connection=utf8mb4')
                logger.info("MySQL データベースに接続しました")
        except Error as e:
            logger.error(f"Error connecting to MySQL: {e}")
            raise

    def disconnect(self):
        if self._cursor:
            self._cursor.close()
        if self._connection and self._connection.is_connected():
            self._connection.close()
            logger.info("MySQL 接続を閉じました")

    def execute_query(self, query: str, params: tuple = None) -> MySQLCursor:
        try:
            self._cursor.execute(query, params)
            return self._cursor
        except Error as e:
            logger.error(f"Error executing query: {e}")
            raise

    def commit(self):
        self._connection.commit()

# Database Operations
class MaterialsDB:
    def __init__(self, settings: Settings):
        self.settings = settings
        if not self.settings.OPENAI_API_KEY:
            logger.error("OpenAI API Key is not set.")
            raise ValueError("OpenAI API Key is required.")
        openai.api_key = self.settings.OPENAI_API_KEY

    def get_materials_by_unit(self, unit_id: int) -> Dict:
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
        with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = db.execute_query(query, (unit_id,))
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

    def get_material_by_id(self, material_id: int) -> MaterialResponse:
        query = """
        SELECT material_id, unit_id, title, description, material_type,
               blob_url, blob_name, file_size, duration, page_count, 
               created_at, updated_at
        FROM lesson_materials 
        WHERE material_id = %s
        """
        with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = db.execute_query(query, (material_id,))
            result = cursor.fetchone()
            if not result:
                logger.info(f"Material not found: material_id={material_id}")
                raise HTTPException(status_code=404, detail="Material not found")
            return MaterialResponse(**result)

    def get_default_unit_materials(self) -> Dict:
        return self.get_materials_by_unit(1)

    def get_current_unit(self, unit_id: int) -> LessonUnit:
        query = """
        SELECT unit_id, field_id, name, order_num, created_at
        FROM units 
        WHERE unit_id = %s
        """
        with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = db.execute_query(query, (unit_id,))
            result = cursor.fetchone()
            if not result:
                logger.info(f"Unit not found: unit_id={unit_id}")
                raise HTTPException(status_code=404, detail="Unit not found")
            return LessonUnit(**result)

    def get_chat_history(self) -> List[ChatConversation]:
        query = """
        SELECT * FROM ai_conversations 
        ORDER BY updated_at DESC
        """
        with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = db.execute_query(query)
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

    def get_conversation_detail(self, conversation_id: int) -> ConversationDetail:
        # 会話の基本情報を取得
        conversation_query = """
        SELECT * FROM ai_conversations 
        WHERE conversation_id = %s
        """
        
        # メッセージを取得
        messages_query = """
        SELECT * FROM messages 
        WHERE conversation_id = %s 
        ORDER BY created_at ASC
        """
        
        with MySQLManager(self.settings.DB_CONFIG) as db:
            # 会話情報の取得
            cursor = db.execute_query(conversation_query, (conversation_id,))
            conversation_result = cursor.fetchone()
            if not conversation_result:
                logger.info(f"Conversation not found: conversation_id={conversation_id}")
                raise HTTPException(status_code=404, detail="Conversation not found")
            
            # メッセージの取得
            cursor = db.execute_query(messages_query, (conversation_id,))
            messages_result = cursor.fetchall()
            
            return ConversationDetail(
                conversation=ChatConversation(**conversation_result),
                messages=[Message(**msg) for msg in messages_result]
            )

    def create_conversation(self, user_id: int, unit_id: int) -> int:
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
        # 初期値の設定
        default_title = '無題の会話'
        default_values = (
            user_id,
            unit_id,
            default_title,   # title
            'summary',            # summary
            False,           # understanding_flag
            False,           # is_public
            0,               # view_count
            0,               # like_count
            0,               # bookmark_count
            False,           # is_pinned
            False,           # is_to_teacher
            'chat',          # teacher_response_type
            'waiting'        # teacher_response_status
        )

        with MySQLManager(self.settings.DB_CONFIG) as db:
            db.execute_query(query, default_values)
            db.commit()
            conversation_id = db._cursor.lastrowid
            logger.info(f"Created new conversation: conversation_id={conversation_id}")
            return conversation_id

    def add_message(self, conversation_id: int, content: str, role: str):
        query = """
        INSERT INTO messages (conversation_id, content, role, created_at)
        VALUES (%s, %s, %s, NOW())
        """
        with MySQLManager(self.settings.DB_CONFIG) as db:
            db.execute_query(query, (conversation_id, content, role))
            db.commit()
            logger.info(f"Added message to conversation_id={conversation_id}: role={role}")

            # 会話の更新日時を更新
            update_query = """
            UPDATE ai_conversations
            SET updated_at = NOW()
            WHERE conversation_id = %s
            """
            db.execute_query(update_query, (conversation_id,))
            db.commit()
            logger.info(f"Updated conversation timestamp: conversation_id={conversation_id}")

    def generate_conversation_title(self, conversation_id: int) -> str:
        messages_query = """
        SELECT content FROM messages WHERE conversation_id = %s ORDER BY created_at ASC
        """
        with MySQLManager(self.settings.DB_CONFIG) as db:
            cursor = db.execute_query(messages_query, (conversation_id,))
            messages = [row['content'] for row in cursor.fetchall()]

        try:
            # 最新のChatCompletion APIを使用
            messages_formatted = [
                {"role": "system", "content": "以下の会話内容に基づいて、簡潔なタイトルを生成してください。"}
            ]
            for msg in messages:
                messages_formatted.append({"role": "user", "content": msg})

            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=messages_formatted,
                max_tokens=10,
                temperature=0.7,
            )
            assistant_message = response['choices'][0]['message']['content'].strip()
            title = assistant_message if assistant_message else "無題の会話"
            logger.info(f"Generated title for conversation_id={conversation_id}: {title}")
        except openai.error.OpenAIError as e:
            logger.error(f"Error generating title: {e}")
            title = "無題の会話"

        update_query = """
        UPDATE ai_conversations SET title = %s WHERE conversation_id = %s
        """
        with MySQLManager(self.settings.DB_CONFIG) as db:
            db.execute_query(update_query, (title, conversation_id))
            db.commit()
            logger.info(f"Updated title for conversation_id={conversation_id}")

        return title

    def send_message(self, conversation_id: int, message: str) -> str:
        """
        OpenAI APIを使用してアシスタントのメッセージを生成し、データベースに保存します。
        """
        try:
            # 最新のChatCompletion APIを使用
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "あなたは高校1年生の物理を教える教師アシスタントです。わかりやすく、丁寧に説明してください。"},
                    {"role": "user", "content": message}
                ],
                max_tokens=150,
                temperature=0.7,
            )
            assistant_message = response['choices'][0]['message']['content'].strip()
            logger.info(f"Generated assistant message for conversation_id={conversation_id}")
        except openai.error.OpenAIError as e:
            logger.error(f"OpenAI API Error: {e}")
            raise HTTPException(status_code=500, detail="Error communicating with OpenAI")
        except Exception as e:
            logger.error(f"Unexpected Error: {e}")
            raise HTTPException(status_code=500, detail="Unexpected Error generating assistant response")

        # アシスタントのメッセージをデータベースに保存
        self.add_message(conversation_id, assistant_message, 'assistant')
        return assistant_message

# FastAPI Application
app = FastAPI(title="Techmagedon API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 必要に応じて制限
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db(settings: Settings = Depends(get_settings)):
    return MaterialsDB(settings)

# Material Endpoints
@app.get("/materials/unit/{unit_id}", response_model=Dict)
async def get_materials_by_unit(unit_id: int, db: MaterialsDB = Depends(get_db)):
    """指定された単元IDに関連する教材を全て取得"""
    return db.get_materials_by_unit(unit_id)

@app.get("/materials/{material_id}", response_model=MaterialResponse)
async def get_material(material_id: int, db: MaterialsDB = Depends(get_db)):
    """指定されたIDの教材を取得"""
    return db.get_material_by_id(material_id)

@app.get("/materials/default", response_model=Dict)
async def get_default_materials(db: MaterialsDB = Depends(get_db)):
    """デフォルトの教材（unit_id=1）を取得"""
    return db.get_default_unit_materials()

@app.get("/units/{unit_id}", response_model=LessonUnit)
async def get_unit(unit_id: int, db: MaterialsDB = Depends(get_db)):
    """指定された単元の情報を取得"""
    return db.get_current_unit(unit_id)

# Chat Endpoints
@app.get("/chat/history", response_model=List[ChatConversation])
async def get_chat_history(db: MaterialsDB = Depends(get_db)):
    """チャット履歴一覧を取得"""
    try:
        return db.get_chat_history()
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        logger.error(f"Unexpected error fetching chat history: {e}")
        raise HTTPException(status_code=500, detail="Unexpected error fetching chat history")

@app.get("/chat/{conversation_id}", response_model=ConversationDetail)
async def get_conversation_detail(conversation_id: int, db: MaterialsDB = Depends(get_db)):
    """特定の会話の詳細を取得"""
    return db.get_conversation_detail(conversation_id)

@app.post("/chat/conversations", response_model=Dict)
async def create_conversation(request: ConversationCreateRequest, db: MaterialsDB = Depends(get_db)):
    """新しい会話を作成"""
    try:
        conversation_id = db.create_conversation(request.user_id, request.unit_id)
        return {"conversation_id": conversation_id}
    except mysql.connector.Error as db_err:
        # データベース関連のエラー
        logger.error(f"Database Error: {db_err}")
        raise HTTPException(status_code=500, detail=f"Database Error: {db_err}")
    except Exception as e:
        # その他のエラー
        logger.error(f"Unexpected Error: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected Error: {e}")

@app.post("/chat/messages", response_model=Dict)
async def add_message(request: MessageCreateRequest, db: MaterialsDB = Depends(get_db)):
    """メッセージを追加"""
    try:
        db.add_message(request.conversation_id, request.content, request.role)
        if request.role == 'user':
            # ユーザーからのメッセージの場合、アシスタントの返信を生成
            assistant_response = db.send_message(request.conversation_id, request.content)
            return {"status": "success", "assistant_message": assistant_response}
        return {"status": "success"}
    except mysql.connector.Error as db_err:
        # データベース関連のエラー
        logger.error(f"Database Error: {db_err}")
        raise HTTPException(status_code=500, detail=f"Database Error: {db_err}")
    except HTTPException as http_exc:
        # OpenAI API関連のエラー
        logger.error(f"HTTP Exception: {http_exc.detail}")
        raise http_exc
    except Exception as e:
        # その他のエラー
        logger.error(f"Unexpected Error: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected Error: {e}")

@app.post("/chat/conversations/{conversation_id}/generate_title", response_model=Dict)
async def generate_title(conversation_id: int, db: MaterialsDB = Depends(get_db)):
    """会話のタイトルを生成"""
    try:
        title = db.generate_conversation_title(conversation_id)
        return {"title": title}
    except mysql.connector.Error as db_err:
        logger.error(f"Database Error: {db_err}")
        raise HTTPException(status_code=500, detail=f"Database Error: {db_err}")
    except Exception as e:
        logger.error(f"Unexpected Error: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected Error: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)