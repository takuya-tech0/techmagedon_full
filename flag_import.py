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
            print(f"クエリを実行しました: {query}")
        except Error as e:
            print(f"Error: {e}")
            raise
        finally:
            if cursor:
                cursor.close()

def update_flags(connector: MySQLConnector):
    """
    ai_conversationsテーブルのフラグを更新
    """
    update_query = """
    UPDATE ai_conversations 
    SET is_public = TRUE,
        is_pinned = TRUE;
    """
    
    try:
        connector.execute_query(update_query)
        print("フラグの更新が完了しました")
    except Exception as e:
        print(f"フラグの更新中にエラーが発生しました: {e}")

def main():
    config = {
        'host': 'tech0-db-step4-studentrdb-3.mysql.database.azure.com',
        'user': 'tech0gen7student',
        'password': 'vY7JZNfU',
        'database': 'techmagedon',
        'client_flags': [mysql.connector.ClientFlag.SSL],
        'ssl_ca': 'DigiCertGlobalRootCA.crt.pem'
    }

    if not Path(config['ssl_ca']).exists():
        raise FileNotFoundError(f"SSL証明書が見つかりません: {config['ssl_ca']}")
    
    connector = MySQLConnector(config)
    
    try:
        update_flags(connector)
    except Exception as e:
        print(f"エラーが発生しました: {e}")
    finally:
        connector.disconnect()

if __name__ == "__main__":
    main()