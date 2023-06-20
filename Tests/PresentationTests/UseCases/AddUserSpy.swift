import Foundation
import Domain

class AddUserSpy: AddUser {
    var userSignBody: UserSignBody?
    var completion: ((Result<UserModel, DomainError>) -> Void)?
    
    func add(userSignBody: UserSignBody, completion: @escaping (Result<UserModel, DomainError>) -> Void) {
        self.userSignBody = userSignBody
        self.completion = completion
    }
    
    func completeWithError(_ error: DomainError) {
        completion?(.failure(error))
    }
    
    func completeWithUser(_ user: UserModel) {
        completion?(.success(user))
    }
}
