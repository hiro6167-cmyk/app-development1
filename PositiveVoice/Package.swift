// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PositiveVoice",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PositiveVoice",
            targets: ["PositiveVoice"]
        ),
    ],
    dependencies: [
        // AWS Amplify
        .package(url: "https://github.com/aws-amplify/amplify-swift.git", from: "2.0.0"),
        // AWS SDK for additional services
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "0.36.0"),
    ],
    targets: [
        .target(
            name: "PositiveVoice",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "AWSAPIPlugin", package: "amplify-swift"),
                .product(name: "AWSDynamoDBPlugin", package: "amplify-swift"),
                .product(name: "AWSS3StoragePlugin", package: "amplify-swift"),
                .product(name: "AWSComprehend", package: "aws-sdk-swift"),
            ],
            path: "PositiveVoice"
        ),
    ]
)
