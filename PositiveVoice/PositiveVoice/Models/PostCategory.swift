import Foundation
import SwiftUI

enum PostCategory: String, Codable, CaseIterable, Identifiable {
    // 今日のいいこと カテゴリ
    case school = "school"
    case friends = "friends"
    case family = "family"
    case hobby = "hobby"
    case achievement = "achievement"
    case nature = "nature"
    case food = "food"

    // こうなって欲しい世の中 カテゴリ
    case environment = "environment"
    case peace = "peace"
    case education = "education"
    case humanRights = "human_rights"
    case technology = "technology"
    case health = "health"
    case community = "community"

    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .school: return "学校・勉強"
        case .friends: return "友人・人間関係"
        case .family: return "家族"
        case .hobby: return "趣味・娯楽"
        case .achievement: return "達成・成長"
        case .nature: return "自然・癒し"
        case .food: return "食事・グルメ"
        case .environment: return "環境・自然"
        case .peace: return "平和・安全"
        case .education: return "教育"
        case .humanRights: return "人権・平等"
        case .technology: return "テクノロジー"
        case .health: return "健康・医療"
        case .community: return "コミュニティ"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .school: return "book.fill"
        case .friends: return "person.2.fill"
        case .family: return "house.fill"
        case .hobby: return "gamecontroller.fill"
        case .achievement: return "star.fill"
        case .nature: return "cloud.sun.fill"  // leaf.fillは緑を想起させるため禁止
        case .food: return "fork.knife"
        case .environment: return "globe.americas.fill"
        case .peace: return "hand.raised.fill"
        case .education: return "graduationcap.fill"
        case .humanRights: return "figure.stand.line.dotted.figure.stand"
        case .technology: return "cpu.fill"
        case .health: return "heart.fill"
        case .community: return "person.3.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    // カラー: 緑系は使用禁止、オレンジ/暖色系で統一
    var color: Color {
        switch self {
        case .school: return AppColors.accent          // コーラル
        case .friends: return AppColors.primary        // オレンジ
        case .family: return .pink
        case .hobby: return .purple
        case .achievement: return AppColors.secondary  // イエロー
        case .nature: return AppColors.success         // オレンジ系（緑禁止）
        case .food: return AppColors.error             // ソフトレッド
        case .environment: return AppColors.accent     // コーラル
        case .peace: return .indigo
        case .education: return AppColors.secondary    // イエロー
        case .humanRights: return AppColors.primary    // オレンジ
        case .technology: return .gray
        case .health: return AppColors.error           // ソフトレッド
        case .community: return AppColors.primary      // オレンジ
        case .other: return AppColors.textSecondary
        }
    }

    var postType: Post.PostType {
        switch self {
        case .school, .friends, .family, .hobby, .achievement, .nature, .food:
            return .goodThing
        case .environment, .peace, .education, .humanRights, .technology, .health, .community:
            return .idealWorld
        case .other:
            return .goodThing
        }
    }

    static func categories(for type: Post.PostType) -> [PostCategory] {
        switch type {
        case .goodThing:
            return [.school, .friends, .family, .hobby, .achievement, .nature, .food, .other]
        case .idealWorld:
            return [.environment, .peace, .education, .humanRights, .technology, .health, .community, .other]
        }
    }
}
