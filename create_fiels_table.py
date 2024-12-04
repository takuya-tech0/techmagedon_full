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

def create_fields_table(connector: MySQLConnector):
    queries = [
        # fieldsテーブルの作成
        """
        CREATE TABLE IF NOT EXISTS fields (
            field_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            subject_id BIGINT UNSIGNED NOT NULL,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            order_num INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
            INDEX idx_subject (subject_id),
            INDEX idx_order (order_num)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """,

        # サンプルデータの挿入（物理の分野）
        """
        INSERT INTO fields (subject_id, name, description, order_num) VALUES 
        (1, '力学', '物体の運動と力の関係について学ぶ分野です。運動方程式、エネルギー、運動量などを扱います。', 1),
        (1, '波動', '波の性質と伝播について学ぶ分野です。音波、光波、振動などを扱います。', 2),
        (1, '熱力学', '熱とエネルギーの関係について学ぶ分野です。気体の状態変化、熱力学の法則などを扱います。', 3),
        (1, '電磁気学', '電気と磁気の性質について学ぶ分野です。電場、磁場、電磁誘導などを扱います。', 4);
        """
    ]

    # テーブル構造の確認
    check_column_query = """
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'units' 
    AND COLUMN_NAME = 'subject_id';
    """

    connector.connect()
    cursor = connector.connection.cursor()
    cursor.execute(check_column_query)
    has_subject_id = cursor.fetchone()[0] > 0
    cursor.close()

    if has_subject_id:
        alter_queries = [
            """
            ALTER TABLE units
            DROP FOREIGN KEY units_ibfk_1;
            """,
            """
            ALTER TABLE units
            CHANGE COLUMN subject_id field_id BIGINT UNSIGNED NOT NULL;
            """,
            """
            ALTER TABLE units
            ADD CONSTRAINT units_ibfk_1
            FOREIGN KEY (field_id) REFERENCES fields(field_id);
            """
        ]
        queries.extend(alter_queries)

    # 既存のunitsデータを一時的に保存
    backup_query = "SELECT * FROM units;"
    connector.connect()
    cursor = connector.connection.cursor(dictionary=True)
    cursor.execute(backup_query)
    existing_units = cursor.fetchall()
    cursor.close()

    # 既存のunitsデータを削除
    delete_query = "DELETE FROM units;"
    connector.execute_query(delete_query)

    # テーブル構造の変更を実行
    for query in queries:
        connector.execute_query(query)

    # 既存のunitsデータを新しい構造で再挿入
    for unit in existing_units:
        restore_query = f"""
        INSERT INTO units (field_id, name, description, order_num) 
        VALUES (1, '{unit['name']}', '{unit['description']}', {unit['order_num']});
        """
        connector.execute_query(restore_query)

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
        create_fields_table(connector)
        print("分野テーブルの作成とデータ移行が完了しました")
    except Exception as e:
        print(f"エラーが発生しました: {e}")
    finally:
        connector.disconnect()

if __name__ == "__main__":
    main()