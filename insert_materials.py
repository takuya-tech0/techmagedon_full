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

def create_lesson_materials_table(connector: MySQLConnector):
    create_table_query = """
    CREATE TABLE IF NOT EXISTS lesson_materials (
        material_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        unit_id BIGINT UNSIGNED NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        material_type ENUM('video', 'pdf') NOT NULL,
        blob_url VARCHAR(1024) NOT NULL,
        blob_name VARCHAR(255) NOT NULL,
        file_size BIGINT UNSIGNED,
        duration INT UNSIGNED,
        page_count INT UNSIGNED,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (unit_id) REFERENCES units(unit_id),
        INDEX idx_unit_type (unit_id, material_type)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    """
    
    connector.execute_query(create_table_query)

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
        create_lesson_materials_table(connector)
        print("lesson_materialsテーブルの作成とサンプルデータの挿入が完了しました")
    except Exception as e:
        print(f"エラーが発生しました: {e}")
    finally:
        connector.disconnect()

if __name__ == "__main__":
    main()