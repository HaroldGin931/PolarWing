//
//  Post.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let userAvatar: String
    let imageUrl: String
    let title: String
    let content: String
    let likes: Int
    let comments: Int
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         username: String,
         userAvatar: String,
         imageUrl: String,
         title: String,
         content: String,
         likes: Int = 0,
         comments: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.username = username
        self.userAvatar = userAvatar
        self.imageUrl = imageUrl
        self.title = title
        self.content = content
        self.likes = likes
        self.comments = comments
        self.createdAt = createdAt
    }
}
