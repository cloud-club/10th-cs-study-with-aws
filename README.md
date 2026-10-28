# 10th-cs-study-with-aws

## 레포 구성

1. 브랜치명
    1. 자유
2. 디렉토리 구조
    
    /concept/week0{1…8}
    
    - 매주 스터디 내용 업로드(자유)
    
    /iac/{username}
    
    - IaC 작성 레포

### IaC 가이드

테라폼이라면 version을 6.68.0으로 통일

```json
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.68.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
```

CDK 활용 가능

```tsx
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';

export class MyCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // S3 버킷 생성 예시
    new s3.Bucket(this, 'MyFirstBucket', {
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // 개발용: 스택 삭제 시 버킷도 함께 삭제
      autoDeleteObjects: true,                  // 개발용: 버킷 내 객체 자동 삭제
    });
  }
}
```

CloudFormation 활용 가능

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Simple S3 bucket creation example'

Parameters:
  EnvironmentName:
    Type: String
    Default: 'dev'
    Description: The environment name (e.g., dev, prod)

Resources:
  MySimpleS3Bucket:
    Type: 'AWS::S3::Bucket'
    Properties:
      BucketName: !Sub 'my-company-bucket-${EnvironmentName}-2026'
      AccessControl: Private
      Tags:
        - Key: Environment
          Ref: EnvironmentName

Outputs:
  BucketNameOutput:
    Description: 'The name of the S3 bucket'
    Value: !Ref MySimpleS3Bucket
```

AWS CLI 활용 가능(비추)

```yaml
aws ec2 start-instances --instance-ids i-1234567890abcdef0
```

## 스터디 진행 방향

매주 월요일까지 과제 종합

1~4주차 

스터디 주제 30분 + 질문사항 10분 + IaC 작성 리뷰 20분

5~8주차

- IaC 담당(미리 도착)
    - 프로비저닝 30분
- 실제 진행
    - 트러블 슈팅 30분
    - 스터디 주제 30분

IaC가 메인인 스터디가 아니므로 샘플 코드받고 트러블 슈팅만 진행 OK
