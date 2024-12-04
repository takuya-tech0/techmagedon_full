import mysql.connector
from mysql.connector import Error

# データベース接続設定
config = {
    'host': 'tech0-db-step4-studentrdb-3.mysql.database.azure.com',
    'user': 'tech0gen7student',
    'password': 'vY7JZNfU',
    'database': 'techmagedon',
    'client_flags': [mysql.connector.ClientFlag.SSL],
    'ssl_ca': 'DigiCertGlobalRootCA.crt.pem'
}

try:
    # データベースに接続
    connection = mysql.connector.connect(**config)

    if connection.is_connected():
        print("MySQL データベースに接続しました")

        cursor = connection.cursor()

        # 外部キー制約の詳細を取得して保存
        cursor.execute("""
            SELECT
                TABLE_NAME,
                CONSTRAINT_NAME,
                COLUMN_NAME,
                REFERENCED_TABLE_NAME,
                REFERENCED_COLUMN_NAME
            FROM
                INFORMATION_SCHEMA.KEY_COLUMN_USAGE
            WHERE
                REFERENCED_TABLE_SCHEMA = '{database}' AND
                REFERENCED_TABLE_NAME = 'ai_conversations' AND
                REFERENCED_COLUMN_NAME = 'conversation_id';
        """.format(database=config['database']))

        fk_constraints = cursor.fetchall()

        # 外部キー制約を一時的に削除
        for table_name, constraint_name, _, _, _ in fk_constraints:
            drop_fk_query = "ALTER TABLE `{table}` DROP FOREIGN KEY `{constraint}`;".format(
                table=table_name,
                constraint=constraint_name
            )
            cursor.execute(drop_fk_query)
            print(f"{table_name} テーブルの外部キー {constraint_name} を削除しました。")

        # AUTO_INCREMENT を追加するクエリ
        alter_query = """
        ALTER TABLE ai_conversations MODIFY COLUMN conversation_id INT NOT NULL AUTO_INCREMENT;
        """

        cursor.execute(alter_query)
        print("conversation_id カラムに AUTO_INCREMENT を追加しました")

        # 外部キー制約を再追加
        for table_name, constraint_name, column_name, ref_table_name, ref_column_name in fk_constraints:
            # 外部キー制約を再追加
            add_fk_query = """
            ALTER TABLE `{table}`
            ADD CONSTRAINT `{constraint}`
            FOREIGN KEY (`{column}`)
            REFERENCES `{ref_table}`(`{ref_column}`)
            ON DELETE CASCADE
            ON UPDATE CASCADE;
            """.format(
                table=table_name,
                constraint=constraint_name,
                column=column_name,
                ref_table=ref_table_name,
                ref_column=ref_column_name
            )
            cursor.execute(add_fk_query)
            print(f"{table_name} テーブルの外部キー {constraint_name} を再追加しました。")

        connection.commit()
        print("すべての操作が正常に完了しました。")

except Error as e:
    print(f"Error: {e}")
    connection.rollback()
finally:
    if connection.is_connected():
        cursor.close()
        connection.close()
        print("MySQL 接続を閉じました")
