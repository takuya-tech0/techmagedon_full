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

def clear_existing_data(connector: MySQLConnector):
    """
    既存のデータを削除
    順序を考慮して削除する必要がある（外部キー制約のため）
    """
    delete_queries = [
        "SET FOREIGN_KEY_CHECKS=0;",  # 外部キーチェックを一時的に無効化
        "TRUNCATE TABLE teacher_views;",
        "TRUNCATE TABLE bookmarks;",
        "TRUNCATE TABLE likes;",
        "TRUNCATE TABLE comments;",
        "TRUNCATE TABLE messages;",
        "TRUNCATE TABLE ai_conversations;",
        "TRUNCATE TABLE lesson_materials;",
        "TRUNCATE TABLE units;",
        "TRUNCATE TABLE fields;",
        "TRUNCATE TABLE subjects;",
        "TRUNCATE TABLE users;",
        "SET FOREIGN_KEY_CHECKS=1;"   # 外部キーチェックを再度有効化
    ]

    for query in delete_queries:
        connector.execute_query(query)
    print("既存のデータを削除しました")

def insert_sample_data(connector: MySQLConnector):
    """
    サンプルデータを挿入
    """
    # [元のクエリリストをそのまま使用]
    queries = [
        # ユーザーデータ
        """
        INSERT INTO users (username, email, password, role) VALUES 
        ('石川先生', 'ishikawa@example.com', 'password123', 'teacher'),
        ('ユーザー1', 'user1@example.com', 'password123', 'student'),
        ('ユーザー2', 'user2@example.com', 'password123', 'student'),
        ('ユーザー3', 'user3@example.com', 'password123', 'student');
        """,
        
        # 物理科目
        """
        INSERT INTO subjects (name, description) VALUES 
        ('物理', '高校物理の基礎から応用までを学習します。物理現象の理解と数学的な取り扱いを学びます。');
        """,

        # 分野データ
        """
        INSERT INTO fields (subject_id, name, description, order_num) VALUES 
        (1, '力学', '物体の運動と力の関係について学ぶ分野です。運動方程式、エネルギー、運動量などを扱います。', 1),
        (1, '波動', '波の性質と伝播について学ぶ分野です。音波、光波、振動などを扱います。', 2),
        (1, '熱力学', '熱とエネルギーの関係について学ぶ分野です。気体の状態変化、熱力学の法則などを扱います。', 3),
        (1, '電磁気学', '電気と磁気の性質について学ぶ分野です。電場、磁場、電磁誘導などを扱います。', 4);
        """,
        
        # 単元データ
        """
        INSERT INTO units (field_id, name, description, order_num) VALUES 
        (1, '第1章 物体の位置、速度、加速度', '運動を表す基本的な物理量について学びます。位置、速度、加速度の概念と計算方法を理解します。', 1),
        (1, '第2章 力とその性質', 'さまざまな力と物体の運動の関係について学びます。重力、摩擦力、弾性力などの基本的な力を理解します。', 2),
        (1, '第3章 運動の法則', 'ニュートンの運動の法則について学びます。慣性の法則、運動方程式、作用・反作用の法則を理解します。', 3),
        (1, '第4章 剛体のつり合い', '力のモーメントと剛体のつり合いについて学びます。てこの原理や重心の概念を理解します。', 4);
        """,

        
        # レッスン教材データ
        """
        INSERT INTO lesson_materials (unit_id, title, description, material_type, blob_url, blob_name, file_size, duration) VALUES 
        (1, '第1講 変位、速度、加速度、等加速度', '加速度の定義と基本的な考え方について解説します。', 'video', 'https://tech0advance2tecmagedon.blob.core.windows.net/lego/sample.mp4', 'sample.mp4', 256000000, 254),
        (1, '第2講 テキスト教材', '基本概念の解説と演習問題', 'pdf', 'https://tech0advance2tecmagedon.blob.core.windows.net/lego/text_sample.png', 'text_sample.png', 150000, NULL);
        """,

        # AI会話データ
        """
        INSERT INTO ai_conversations (user_id, unit_id, title, summary, understanding_flag) VALUES 
        (1, 1, '加速度の意味について', '加速度の定義と計算方法について質問し、基本的な概念を理解しました。', TRUE),
        (2, 1, '速度と加速度の違い', '速度と加速度の関係性について確認し、それぞれの特徴を理解しました。', TRUE),
        (3, 2, '力の種類について', '重力、摩擦力、弾性力などについて質問し、基本的な力の性質を学びました。', FALSE);
        """,
        
       # メッセージデータ
        """
        INSERT INTO messages (conversation_id, content, role) VALUES 
        (1, '加速度のところが全然わかりません...微分とか出てきて難しいんですが、どうやって理解したらいいですか？', 'user'),
        (1, '加速度は「速度の変化の割合」を表しています。微分は難しく感じるかもしれませんが、まずは直感的な理解から始めましょう。例えば、車の速度計を見ていると、速度が時間とともに変化しますよね。この「変化の速さ」が加速度です。', 'ai'),
        (1, 'なるほど！でも、なんで加速度の単位が m/s² になるんですか？速さは m/s なのに...', 'user'),
        (1, '良い質問ですね！これは「1秒あたりの速度の変化量」を表しているからです。例えば、3 m/s² の加速度は、「1秒ごとに速度が3 m/s ずつ増える」という意味です。最初は0 m/s、1秒後に3 m/s、2秒後に6 m/s、というように変化していきます。', 'ai'),
        (1, 'あっ！そういうことだったんですね。じゃあ、自由落下のときの加速度って、どうして9.8 m/s²なんですか？重力と関係あるんですか？', 'user'),
        (1, 'はい、その通りです！地球の重力によって、物体は毎秒約9.8 m/s ずつ速度を増していきます。これを重力加速度と呼び、通常 g で表します。面白いことに、重さに関係なく、どんな物体も同じ加速度で落下します（空気抵抗がない場合）。', 'ai'),
        (1, 'へぇ〜！重い物も軽い物も同じ加速度で落ちるなんてすごいですね。でも、現実では重い物の方が早く落ちてきませんか？', 'user'),
        (1, 'その違いは空気抵抗によるものです。空気抵抗は物体の形や大きさに依存するので、例えば同じ大きさの鉄球と紙球を落とすと、確かに鉄球の方が早く落ちます。でも、真空中で実験すると、ガリレオが証明したように、本当に同じ速さで落ちるんですよ。月面でのハンマーと羽の落下実験は、この現象を美しく示しています。', 'ai'),
        (2, '速度と加速度の違いがイマイチ分かりません...特に円運動のところで、等速円運動なのに加速度があるって言われて混乱してます。教科書読んでもよく分からなくて...', 'user'),
        (2, 'なるほど、確かに紛らわしいですよね。まず、速度は「どれだけ速く動いているか」だけでなく、「どの向きに動いているか」も表していることが重要です。加速度は、この速度の変化を表しています。', 'ai'),
        (2, 'えっと...じゃあ円運動の場合は、速さは同じでも向きが変わっているから加速度があるってことですか？', 'user'),
        (2, 'その通りです！例えば、遊園地のメリーゴーラウンドを思い浮かべてみてください。速さは一定でも、常に進む向きが変わっていますよね。この「向きの変化」を生み出すために、中心方向への加速度（向心加速度）が必要なんです。', 'ai'),
        (2, '中心に向かう加速度って、具体的には何が起こってるんですか？メリーゴーラウンドが回り続けられるのはなぜですか？', 'user'),
        (2, '円運動を続けるには、常に中心方向への力が必要です。メリーゴーラウンドの場合は、支柱やアームの構造が中心への力を提供しています。別の例では、人工衛星は地球の重力、惑星は太陽の重力が向心力として働いています。', 'ai'),
        (2, 'あっ！なるほど！じゃあ、その力がないと物体は円運動できないってことですかね？野球のボールとか。', 'user'),
        (2, 'その通りです！例えば、糸に繋がれたボールを回すとき、糸が切れたら、ボールは接線方向（その時の速度の向き）に飛んでいきますよね。これは、向心力を失ったため、慣性の法則に従って直線運動をするようになるからなんです。', 'ai'),
        (3, '先生、力ってたくさん種類があって覚えきれないんですけど...重要なポイントってどこを押さえればいいですか？特に保存力と散逸力の違いがよく分かりません...', 'user'),
        (3, 'そうですね。力は大きく「保存力」と「散逸力」に分類できます。保存力は、重力や弾性力のように、エネルギーを保存する力です。一方、散逸力は摩擦力のように、運動エネルギーを熱などに変換してしまう力です。', 'ai'),
        (3, 'あ、だから摩擦があると物体は最後に止まっちゃうんですね！でも重力は永遠に働き続けるってことですか？', 'user'),
        (3, '良い気づきですね！そうなんです。例えば、理想的な振り子（摩擦がない場合）は、重力が保存力なので永遠に振動し続けます。でも現実には空気抵抗や支点の摩擦があるため、次第に振動が小さくなって止まってしまいます。', 'ai'),
        (3, '最近、静電気が気になってるんですが、静電気の力って保存力なんですか？それとも散逸力？', 'user'),
        (3, 'クーロン力（静電気力）は保存力です！重力と似た性質を持っていて、距離の二乗に反比例します。面白いことに、この類似性は現代物理学でも重要な意味を持っています。ただし、静電気が放電するときは、電気エネルギーが熱や光に変換されますよ。', 'ai'),
        (3, 'へぇ〜！じゃあ雷って、静電気が大規模に放電してるってことなんですかね？すごい音や光が出るのも、エネルギー変換だからですか？', 'user'),
        (3, 'その通りです！雷は自然界における最大規模の静電気放電現象です。雲と地面の間に大きな電位差が生じ、一瞬で莫大な電気エネルギーが解放されます。光、音、熱、そして空気の急激な膨張による衝撃波まで、様々な形態にエネルギーが変換されているんですよ。', 'ai');
        """,
        
        # コメントデータ
        """
        INSERT INTO comments (conversation_id, user_id, content) VALUES 
        (1, 1, '良い質問ですね。加速度の概念は物理学の基礎として非常に重要です。具体例を用いた説明が分かりやすいですね。'),
        (1, 2, '私も同じところで悩んでいました。この説明で加速度の概念がよく理解できました。特に具体例が参考になります。'),
        (2, 2, '図を使って説明するとより分かりやすいかもしれません。速度-時間グラフなどを活用すると、加速度の概念がより明確になりますよ。');
        """,
        
        # いいねデータ
        """
        INSERT INTO likes (conversation_id, user_id) VALUES 
        (1, 1),
        (2, 2),
        (3, 3),
        (1, 4);
        """,
        
        # ブックマークデータ
        """
        INSERT INTO bookmarks (conversation_id, user_id) VALUES 
        (1, 1),
        (2, 2),
        (3, 3);
        """,
        
        # 教師の閲覧履歴
        """
        INSERT INTO teacher_views (conversation_id, user_id) VALUES 
        (1, 1),
        (2, 1),
        (3, 2);
        """
    ]
    
    for query in queries:
        connector.execute_query(query)

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
        # 既存データの削除
        clear_existing_data(connector)
        
        # 新しいデータの挿入
        insert_sample_data(connector)
        print("サンプルデータの更新が完了しました")
    except Exception as e:
        print(f"エラーが発生しました: {e}")
    finally:
        connector.disconnect()

if __name__ == "__main__":
    main()