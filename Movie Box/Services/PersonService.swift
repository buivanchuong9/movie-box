import Foundation

protocol PersonServiceProtocol {
    func details(id: Int) async throws -> PersonDetail
}
