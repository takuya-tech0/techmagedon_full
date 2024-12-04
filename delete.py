import mysql.connector
from mysql.connector import Error
from typing import Dict, Any, Optional
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

    def execute_query_with_params(self, query: str, params: Optional[tuple] = None):
        """
        パラメータ化されたクエリを実行します。
        """
        try:
            self.connect()
            cursor = self.connection.cursor()
            cursor.execute(query, params)
            self.connection.commit()
            print(f"クエリを実行しました: {cursor.statement}")
        except Error as e:
            print(f"Error: {e}")
            raise
        finally:
            if cursor:
                cursor.close()

def delete_conversation(connector: MySQLConnector, conversation_id: int):
    """
    指定された conversation_id を ai_conversations テーブルから削除します。
    """
    delete_query = "DELETE FROM ai_conversations WHERE conversation_id = %s;"
    try:
        connector.execute_query_with_params(delete_query, (conversation_id,))
        print(f"conversation_id {conversation_id} を削除しました")
    except Exception as e:
        print(f"conversation_id {conversation_id} の削除中にエラーが発生しました: {e}")

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
        # 削除したい conversation_id を指定
        conversation_id_to_delete = 10  # ここに削除したい conversation_id を設定
        
        # 指定された conversation_id を削除
        delete_conversation(connector, conversation_id_to_delete)
        print("削除処理が完了しました")
    except Exception as e:
        print(f"エラーが発生しました: {e}")
    finally:
        connector.disconnect()

if __name__ == "__main__":
    main()
