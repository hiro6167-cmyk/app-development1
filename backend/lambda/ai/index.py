import json
import boto3

comprehend = boto3.client('comprehend')
bedrock = boto3.client('bedrock-runtime')

def lambda_handler(event, context):
    http_method = event['httpMethod']
    path = event['path']

    try:
        if '/classify' in path:
            return classify_post(event)
        elif '/moderate' in path:
            return moderate_content(event)
        elif '/embedding' in path:
            return generate_embedding(event)
        elif '/sentiment' in path:
            return analyze_sentiment(event)
        else:
            return response(404, {'error': 'Not found'})
    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': str(e)})


def classify_post(event):
    """投稿をカテゴリに分類"""
    body = json.loads(event['body'])
    content = body.get('content', '')
    post_type = body.get('type', 'good_thing')

    categories_good = [
        ('school', '学校・勉強に関する内容'),
        ('friends', '友人・人間関係に関する内容'),
        ('family', '家族に関する内容'),
        ('hobby', '趣味・娯楽に関する内容'),
        ('achievement', '達成・成長に関する内容'),
        ('nature', '自然・癒しに関する内容'),
        ('food', '食事・グルメに関する内容'),
        ('other', 'その他')
    ]

    categories_ideal = [
        ('environment', '環境・自然に関する内容'),
        ('peace', '平和・安全に関する内容'),
        ('education', '教育に関する内容'),
        ('human_rights', '人権・平等に関する内容'),
        ('technology', 'テクノロジーに関する内容'),
        ('health', '健康・医療に関する内容'),
        ('community', 'コミュニティに関する内容'),
        ('other', 'その他')
    ]

    categories = categories_good if post_type == 'good_thing' else categories_ideal
    categories_str = '\n'.join([f"- {c[0]}: {c[1]}" for c in categories])

    prompt = f"""あなたは投稿を分類するAIアシスタントです。
以下の投稿を最も適切なカテゴリに分類してください。

カテゴリ一覧:
{categories_str}

投稿内容:
{content}

JSONで回答してください:
{{"category": "カテゴリ名", "confidence": 0.0-1.0}}"""

    try:
        result = bedrock.invoke_model(
            modelId='anthropic.claude-3-haiku-20240307-v1:0',
            body=json.dumps({
                'anthropic_version': 'bedrock-2023-05-31',
                'max_tokens': 100,
                'messages': [{'role': 'user', 'content': prompt}]
            })
        )

        ai_response = json.loads(result['body'].read())
        text = ai_response['content'][0]['text']

        # JSONをパース
        import re
        json_match = re.search(r'\{.*\}', text, re.DOTALL)
        if json_match:
            classification = json.loads(json_match.group())
            return response(200, classification)

        return response(200, {'category': 'other', 'confidence': 0.5})
    except Exception as e:
        print(f"Classification error: {e}")
        return response(200, {'category': 'other', 'confidence': 0.0})


def moderate_content(event):
    """不適切コンテンツを検出"""
    body = json.loads(event['body'])
    content = body.get('content', '')

    try:
        # 感情分析
        sentiment_result = comprehend.detect_sentiment(
            Text=content,
            LanguageCode='ja'
        )

        negative_score = sentiment_result['SentimentScore']['Negative']

        # 有害コンテンツ検出（Bedrockを使用）
        prompt = f"""以下のテキストが不適切かどうか判定してください。
不適切な内容とは、暴力的、差別的、性的、誹謗中傷などを含むものです。

テキスト:
{content}

JSONで回答してください:
{{"isInappropriate": true/false, "reason": "理由（不適切な場合のみ）", "confidence": 0.0-1.0}}"""

        result = bedrock.invoke_model(
            modelId='anthropic.claude-3-haiku-20240307-v1:0',
            body=json.dumps({
                'anthropic_version': 'bedrock-2023-05-31',
                'max_tokens': 200,
                'messages': [{'role': 'user', 'content': prompt}]
            })
        )

        ai_response = json.loads(result['body'].read())
        text = ai_response['content'][0]['text']

        import re
        json_match = re.search(r'\{.*\}', text, re.DOTALL)
        if json_match:
            moderation = json.loads(json_match.group())

            # ネガティブスコアが高い場合も考慮
            if negative_score > 0.8:
                moderation['isInappropriate'] = True
                moderation['reason'] = moderation.get('reason', '') + ' (High negative sentiment)'

            return response(200, moderation)

        return response(200, {
            'isInappropriate': negative_score > 0.8,
            'reason': 'High negative sentiment' if negative_score > 0.8 else None,
            'confidence': negative_score
        })
    except Exception as e:
        print(f"Moderation error: {e}")
        return response(200, {
            'isInappropriate': False,
            'reason': None,
            'confidence': 0.0
        })


def generate_embedding(event):
    """テキストのembeddingを生成"""
    body = json.loads(event['body'])
    content = body.get('content', '')

    try:
        result = bedrock.invoke_model(
            modelId='amazon.titan-embed-text-v1',
            body=json.dumps({'inputText': content})
        )

        embedding_result = json.loads(result['body'].read())
        embedding = embedding_result.get('embedding', [])

        return response(200, {'embedding': embedding})
    except Exception as e:
        print(f"Embedding error: {e}")
        return response(200, {'embedding': []})


def analyze_sentiment(event):
    """感情分析"""
    body = json.loads(event['body'])
    content = body.get('content', '')

    try:
        result = comprehend.detect_sentiment(
            Text=content,
            LanguageCode='ja'
        )

        return response(200, {
            'sentiment': result['Sentiment'],
            'positiveScore': result['SentimentScore']['Positive'],
            'negativeScore': result['SentimentScore']['Negative'],
            'neutralScore': result['SentimentScore']['Neutral'],
            'mixedScore': result['SentimentScore']['Mixed']
        })
    except Exception as e:
        print(f"Sentiment error: {e}")
        return response(500, {'error': str(e)})


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
