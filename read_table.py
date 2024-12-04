import mysql.connector
from mysql.connector import Error
from typing import Dict, Any, List
from pathlib import Path
from tabulate import tabulate

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

    def fetch_records(self, table_name: str) -> tuple[List[str], List[tuple]]:
        """
        指定されたテーブルのレコードを取得
        
        Args:
            table_name (str): テーブル名
            
        Returns:
            tuple[List[str], List[tuple]]: カラム名のリストとレコードのリスト
        """
        try:
            self.connect()
            cursor = self.connection.cursor()
            
            # カラム情報を取得
            cursor.execute(f"DESCRIBE {table_name};")
            columns = [column[0] for column in cursor.fetchall()]
            
            # レコードを取得
            cursor.execute(f"SELECT * FROM {table_name};")
            records = cursor.fetchall()
            
            return columns, records
            
        except Error as e:
            print(f"Error: {e}")
            raise
        finally:
            if cursor:
                cursor.close()

def display_table_records(table_name: str, connector: MySQLConnector):
    """
    テーブルのレコードを表示
    
    Args:
        table_name (str): テーブル名
        connector (MySQLConnector): データベース接続オブジェクト
    """
    try:
        columns, records = connector.fetch_records(table_name)
        
        if not records:
            print(f"\n{table_name}テーブルにレコードが存在しません。")
            return
            
        print(f"\n{table_name}テーブルのレコード:")
        print(tabulate(records, headers=columns, tablefmt='grid'))
        print(f"総レコード数: {len(records)}")
        
    except Exception as e:
        print(f"テーブルの表示中にエラーが発生しました: {e}")

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
        while True:
            # 利用可能なテーブルを表示
            print("\n利用可能なテーブル:")
            print("1. users")
            print("2. subjects")
            print("3. units")
            print("4. ai_conversations")
            print("5. messages")
            print("6. comments")
            print("7. likes")
            print("8. bookmarks")
            print("9. teacher_views")
            print("0. 終了")
            
            choice = input("\n表示するテーブルの番号を入力してください (0-9): ")
            
            if choice == '0':
                break
                
            table_mapping = {
                '1': 'users',
                '2': 'subjects',
                '3': 'units',
                '4': 'ai_conversations',
                '5': 'messages',
                '6': 'comments',
                '7': 'likes',
                '8': 'bookmarks',
                '9': 'teacher_views'
            }
            
            if choice in table_mapping:
                display_table_records(table_mapping[choice], connector)
            else:
                print("無効な選択です。もう一度お試しください。")
                
    except Exception as e:
        print(f"エラーが発生しました: {e}")
    finally:
        connector.disconnect()

if __name__ == "__main__":
    main()