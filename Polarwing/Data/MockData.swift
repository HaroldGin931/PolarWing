//
//  MockData.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import Foundation

struct MockData {
    static let posts: [Post] = [
        Post(
            userId: "user1",
            username: "Alice",
            userAvatar: "person.circle.fill",
            imageUrl: "photo.fill",
            title: "美好的早晨",
            content: "今天天气真好，拍了一张美照分享给大家！",
            likes: 128,
            comments: 23,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Post(
            userId: "user2",
            username: "Bob",
            userAvatar: "person.circle.fill",
            imageUrl: "photo.fill",
            title: "咖啡时光",
            content: "下午茶时间，享受这份宁静",
            likes: 256,
            comments: 42,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        Post(
            userId: "user3",
            username: "Charlie",
            userAvatar: "person.circle.fill",
            imageUrl: "photo.fill",
            title: "城市夜景",
            content: "夜幕降临，城市开始闪耀",
            likes: 512,
            comments: 67,
            createdAt: Date().addingTimeInterval(-86400)
        ),
        Post(
            userId: "user4",
            username: "Diana",
            userAvatar: "person.circle.fill",
            imageUrl: "photo.fill",
            title: "周末出游",
            content: "终于可以放松一下了",
            likes: 89,
            comments: 15,
            createdAt: Date().addingTimeInterval(-172800)
        ),
        Post(
            userId: "user5",
            username: "Eve",
            userAvatar: "person.circle.fill",
            imageUrl: "photo.fill",
            title: "美食分享",
            content: "今天做的料理，味道还不错",
            likes: 342,
            comments: 56,
            createdAt: Date().addingTimeInterval(-259200)
        ),
        Post(
            userId: "user6",
            username: "Frank",
            userAvatar: "person.circle.fill",
            imageUrl: "photo.fill",
            title: "健身打卡",
            content: "坚持就是胜利！",
            likes: 198,
            comments: 31,
            createdAt: Date().addingTimeInterval(-345600)
        )
    ]
}
