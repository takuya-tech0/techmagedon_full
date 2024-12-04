from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict
from pydantic import BaseModel
from datetime import datetime
import mysql.connector
from mysql.connector import Error
from mysql.connector.cursor import MySQLCursor
import os
from functools import lru_cache

# Config model
class Settings:
    def __init__(self):
        self.MYSQL_HOST = 'tech0-db-step4-studentrdb-3.mysql.database.azure.com'
        self.MYSQL_USER = 'tech0gen7student'
        self.MYSQL_PASSWORD = 'vY7JZNfU'
        self.MYSQL_DATABASE = 'techmagedon'
        self.SSL_CA = 'DigiCertGlobalRootCA.crt.pem'

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
            print(f"Warning: SSL certificate file not found at {self.SSL_CA}")
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
    title: str
    description: str
    material_type: str
    blob_url: str
    blob_name: str
    file_size: int
    duration: int | None
    page_count: int | None
    created_at: datetime
    updated_at: datetime

class LessonUnit(BaseModel):
    unit_id: int
    field_id: int
    name: str
    order_num: int
    created_at: datetime

class Message(BaseModel):
    message_id: int
    conversation_id: int
    content: str
    role: str
    created_at: datetime

class ChatConversation(BaseModel):
    conversation_id: int
    user_id: int
    unit_id: int
    title: str
    summary: str
    understanding_flag: bool
    created_at: datetime
    updated_at: datetime
    is_public: bool
    view_count: int
    like_count: int
    bookmark_count: int
    is_pinned: bool
    is_to_teacher: bool
    teacher_response_type: str | None
    teacher_response_status: str | None

class ConversationDetail(BaseModel):
    conversation: ChatConversation
    messages: List[Message]

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
        except Error as e:
            print(f"Error connecting to MySQL: {e}")
            raise

    def disconnect(self):
        if self._cursor:
            self._cursor.close()
        if self._connection and self._connection.is_connected():
            self._connection.close()

    def execute_query(self, query: str, params: tuple = None) -> MySQLCursor:
        try:
            self._cursor.execute(query, params)
            return self._cursor
        except Error as e:
            print(f"Error executing query: {e}")
            raise

    def commit(self):
        self._connection.commit()

# Database Operations
class MaterialsDB:
    def __init__(self, settings: Settings):
        self.settings = settings

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
                return []
            return [ChatConversation(**result) for result in results]

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
                raise HTTPException(status_code=404, detail="Conversation not found")
            
            # メッセージの取得
            cursor = db.execute_query(messages_query, (conversation_id,))
            messages_result = cursor.fetchall()
            
            return ConversationDetail(
                conversation=ChatConversation(**conversation_result),
                messages=[Message(**msg) for msg in messages_result]
            )

# FastAPI Application
app = FastAPI(title="Techmagedon API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db(settings: Settings = Depends(get_settings)):
    return MaterialsDB(settings)

@app.get("/materials/unit/{unit_id}")
async def get_materials_by_unit(unit_id: int, db: MaterialsDB = Depends(get_db)):
    """指定された単元IDに関連する教材を全て取得"""
    return db.get_materials_by_unit(unit_id)

@app.get("/materials/{material_id}", response_model=MaterialResponse)
async def get_material(material_id: int, db: MaterialsDB = Depends(get_db)):
    """指定されたIDの教材を取得"""
    return db.get_material_by_id(material_id)

@app.get("/materials/default")
async def get_default_materials(db: MaterialsDB = Depends(get_db)):
    """デフォルトの教材（unit_id=1）を取得"""
    return db.get_default_unit_materials()

@app.get("/units/{unit_id}", response_model=LessonUnit)
async def get_unit(unit_id: int, db: MaterialsDB = Depends(get_db)):
    """指定された単元の情報を取得"""
    return db.get_current_unit(unit_id)

@app.get("/chat/history", response_model=List[ChatConversation])
async def get_chat_history(db: MaterialsDB = Depends(get_db)):
    """チャット履歴一覧を取得"""
    return db.get_chat_history()

@app.get("/chat/{conversation_id}", response_model=ConversationDetail)
async def get_conversation_detail(conversation_id: int, db: MaterialsDB = Depends(get_db)):
    """特定の会話の詳細を取得"""
    return db.get_conversation_detail(conversation_id)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)