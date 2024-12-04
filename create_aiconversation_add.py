    import mysql.connector
from mysql.connector import Error
from typing import Dict, Any
from pathlib import Path

class MySQLConnector:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.connection = None

    def connect(self):
        try:
            if not self.connection or not self.connection.is_connected():
                self.connection = mysql.connector.connect(**self.config)
                print("MySQL データベースに接続しました")
        except Error as e:
            print(f"Error: {e}")
            raise

    def disconnect(self):
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("MySQL 接続を閉じました")

    def execute_query(self, query: str):
        try:
            self.connect()
            cursor = self.connection.cursor()
            cursor.execute(query)
            self.connection.commit()
            print(f"クエリを実行しました: {query[:100]}...")
        except Error as e:
            print(f"Error: {e}")
            raise
        finally:
            if cursor:
                cursor.close()

def add_columns(connector: MySQLConnector):
    """
    ai_conversationsテーブルに新しいカラムを追加
    
    Args:
        connector (MySQLConnector): データベース接続オブジェクト
    """
    alter_query = """
    ALTER TABLE ai_conversations
        ADD COLUMN is_public BOOLEAN NOT NULL DEFAULT FALSE,
        ADD COLUMN view_count INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN like_count INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN bookmark_count INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
        ADD INDEX idx_is_public (is_public),
        ADD INDEX idx_user_pinned (user_id, is_pinned);
    """
    
    try:
        connector.execute_query(alter_query)
        print("新しいカラムを追加しました")
    except Exception as e:
        print(f"カラムの追加中にエラーが発生しました: {e}")

def main():
    # データベース接続設定
    config = {
        'host': 'tech0-db-step4-studentrdb-3.mysql.database.azure.com',
        'user': 'tech0gen7student',
        'password': 'vY7JZNfU',
        'database': 'techmagedon',
        'client_flags': [mysql.connector.ClientFlag.SSL],
        'ssl_ca': 'DigiCertGlobalRootCA.crt.pem'
    }

    # SSL証明書の存在確認
    if not Path(config['ssl_ca']).exists():
        raise FileNotFoundError(f"SSL証明書が見つかりません: {config['ssl_ca']}")
    
    # データベース接続オブジェクトを作成
    connector = MySQLConnector(config)
    
    try:
        # 新しいカラムを追加
        add_columns(connector)
        print("カラムの追加が完了しました")
    except Exception as e:
        print(f"エラーが発生しました: {e}")
    finally:
        # 接続を閉じる
        connector.disconnect()

if __name__ == "__main__":
    main()