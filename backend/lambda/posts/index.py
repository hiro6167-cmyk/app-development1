import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
posts_table = dynamodb.Table('PositiveVoice-Posts')
comprehend = boto3.client('comprehend')
bedrock = boto3.client('bedrock-runtime')

def lambda_handler(event, context):
    http_method = event['httpMethod']
    path = event['path']

    try:
        if http_method == 'GET':
            if '/similar' in path:
                return get_similar_posts(event)
            elif '/search' in path:
                return search_posts(event)
            elif '/me' in path:
                return get_my_posts(event)
            else:
                return get_posts(event)
        elif http_method == 'POST':
            return create_post(event)
        elif http_method == 'DELETE':
            return delete_post(event)
        else:
            return response(405, {'error': 'Method not allowed'})
    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': str(e)})


def create_post(event):
    """新規投稿を作成"""
    body = json.loads(event['body'])
    user_id = event['requestContext']['authorizer']['claims']['sub']

    content = body.get('content', '').strip()
    post_type = body.get('type', 'good_thing')

    if not content:
        return response(400, {'error': 'Content is required'})

    if len(content) > 300:
        return response(400, {'error': 'Content too long (max 300 characters)'})

    # モデレーション（不適切コンテンツチェック）
    is_inappropriate = moderate_content(content)
    if is_inappropriate:
        return response(400, {'error': 'Inappropriate content detected'})

    # AIでカテゴリを自動分類
    category = classify_content(content, post_type)

    # 類似検索用のembeddingを生成
    embedding = generate_embedding(content)

    post_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()

    item = {
        'postId': post_id,
        'userId': user_id,
        'type': post_type,
        'content': content,
        'category': category,
        'embedding': embedding,
        'isVisible': True,
        'createdAt': now
    }

    posts_table.put_item(Item=item)

    return response(201, item)


def get_posts(event):
    """投稿一覧を取得"""
    params = event.get('queryStringParameters', {}) or {}
    post_type = params.get('type', 'good_thing')
    sort_order = params.get('sort', 'newest')
    limit = int(params.get('limit', 20))

    # DynamoDBからクエリ
    result = posts_table.query(
        IndexName='type-createdAt-index',
        KeyConditionExpression='#type = :type',
        ExpressionAttributeNames={'#type': 'type'},
        ExpressionAttributeValues={':type': post_type},
        ScanIndexForward=(sort_order != 'newest'),
        Limit=limit
    )

    posts = result.get('Items', [])

    # おすすめ順の場合はシャッフル（本番ではAIベースのレコメンドを実装）
    if sort_order == 'recommended':
        import random
        random.shuffle(posts)

    return response(200, {
        'posts': posts,
        'nextToken': result.get('LastEvaluatedKey')
    })


def get_similar_posts(event):
    """類似投稿を取得"""
    path_params = event.get('pathParameters', {})
    post_id = path_params.get('id')
    limit = int(event.get('queryStringParameters', {}).get('limit', 5))

    # 対象の投稿を取得
    result = posts_table.get_item(Key={'postId': post_id})
    post = result.get('Item')

    if not post:
        return response(404, {'error': 'Post not found'})

    # embeddingを使用して類似投稿を検索
    # 本番ではOpenSearch/PineconeなどのベクトルDBを使用
    similar_posts = find_similar_by_embedding(
        post.get('embedding', []),
        post.get('type'),
        post_id,
        limit
    )

    return response(200, {
        'posts': similar_posts
    })


def search_posts(event):
    """投稿を検索"""
    params = event.get('queryStringParameters', {}) or {}
    query = params.get('q', '')
    post_type = params.get('type')
    category = params.get('category')

    # 簡易検索（本番ではOpenSearchを使用）
    filter_expression = 'isVisible = :visible'
    expression_values = {':visible': True}

    if post_type:
        filter_expression += ' AND #type = :type'
        expression_values[':type'] = post_type

    if category:
        filter_expression += ' AND category = :category'
        expression_values[':category'] = category

    result = posts_table.scan(
        FilterExpression=filter_expression,
        ExpressionAttributeValues=expression_values,
        ExpressionAttributeNames={'#type': 'type'} if post_type else {}
    )

    posts = result.get('Items', [])

    # キーワードフィルタリング
    if query:
        posts = [p for p in posts if query.lower() in p.get('content', '').lower()]

    return response(200, {
        'posts': posts[:20]
    })


def get_my_posts(event):
    """自分の投稿を取得"""
    user_id = event['requestContext']['authorizer']['claims']['sub']

    result = posts_table.query(
        IndexName='userId-createdAt-index',
        KeyConditionExpression='userId = :userId',
        ExpressionAttributeValues={':userId': user_id},
        ScanIndexForward=False
    )

    return response(200, {
        'posts': result.get('Items', [])
    })


def delete_post(event):
    """投稿を削除"""
    path_params = event.get('pathParameters', {})
    post_id = path_params.get('id')
    user_id = event['requestContext']['authorizer']['claims']['sub']

    # 投稿の所有者確認
    result = posts_table.get_item(Key={'postId': post_id})
    post = result.get('Item')

    if not post:
        return response(404, {'error': 'Post not found'})

    if post.get('userId') != user_id:
        return response(403, {'error': 'Not authorized'})

    posts_table.delete_item(Key={'postId': post_id})

    return response(200, {'message': 'Post deleted'})


# ==================== AI Functions ====================

def moderate_content(content):
    """Amazon Comprehendで不適切コンテンツを検出"""
    try:
        result = comprehend.detect_sentiment(
            Text=content,
            LanguageCode='ja'
        )

        # ネガティブ度が高い場合は不適切と判定
        negative_score = result['SentimentScore']['Negative']
        if negative_score > 0.8:
            return True

        # 有害コンテンツ検出（Toxicity Detection）
        # 本番では専用のモデレーションAPIを使用

        return False
    except Exception as e:
        print(f"Moderation error: {e}")
        return False


def classify_content(content, post_type):
    """AIでコンテンツを分類"""
    categories_good = ['school', 'friends', 'family', 'hobby', 'achievement', 'nature', 'food', 'other']
    categories_ideal = ['environment', 'peace', 'education', 'human_rights', 'technology', 'health', 'community', 'other']

    categories = categories_good if post_type == 'good_thing' else categories_ideal

    try:
        # Amazon Bedrockを使用してカテゴリを分類
        prompt = f"""以下の投稿を最も適切なカテゴリに分類してください。
カテゴリ: {', '.join(categories)}

投稿: {content}

カテゴリ名のみを回答してください。"""

        response = bedrock.invoke_model(
            modelId='anthropic.claude-3-haiku-20240307-v1:0',
            body=json.dumps({
                'anthropic_version': 'bedrock-2023-05-31',
                'max_tokens': 50,
                'messages': [{'role': 'user', 'content': prompt}]
            })
        )

        result = json.loads(response['body'].read())
        category = result['content'][0]['text'].strip().lower()

        if category in categories:
            return category
        return 'other'
    except Exception as e:
        print(f"Classification error: {e}")
        return 'other'


def generate_embedding(content):
    """類似検索用のembeddingを生成"""
    try:
        # Amazon Titan Embeddingsを使用
        response = bedrock.invoke_model(
            modelId='amazon.titan-embed-text-v1',
            body=json.dumps({'inputText': content})
        )

        result = json.loads(response['body'].read())
        return result.get('embedding', [])
    except Exception as e:
        print(f"Embedding error: {e}")
        return []


def find_similar_by_embedding(embedding, post_type, exclude_id, limit):
    """embeddingを使用して類似投稿を検索（簡易版）"""
    # 本番ではOpenSearch/PineconeなどのベクトルDBを使用
    # ここでは同じタイプの最新投稿を返す

    result = posts_table.query(
        IndexName='type-createdAt-index',
        KeyConditionExpression='#type = :type',
        ExpressionAttributeNames={'#type': 'type'},
        ExpressionAttributeValues={':type': post_type},
        ScanIndexForward=False,
        Limit=limit + 1
    )

    posts = [p for p in result.get('Items', []) if p.get('postId') != exclude_id]
    return posts[:limit]


def response(status_code, body):
    """API Gatewayレスポンスを生成"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': True
        },
        'body': json.dumps(body, default=str)
    }
