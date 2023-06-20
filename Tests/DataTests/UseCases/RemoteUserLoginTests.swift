import XCTest
import Domain
import Data

final class RemoteUserLoginTests: XCTestCase {

    func test_login_should_call_httpClient_with_corret_url() throws {
        let url: URL = makeURL()
        let (sut, httpClientSpy) = makeSut()
        sut.login(userSignBody: makeUserSignBody()) { _ in }
        XCTAssertEqual(httpClientSpy.urls, [url])
    }
    
    func test_login_should_call_httpClient_with_corret_data() throws {
        let (sut, httpClientSpy) = makeSut()
        let userSignBody: UserSignBody = makeUserSignBody()
        sut.login(userSignBody: makeUserSignBody()) { _ in }
        XCTAssertEqual(httpClientSpy.data, userSignBody.toData())
    }
    
    func test_login_should_complete_with_error_if_client_complete_with_failure() throws {
        let (sut, httpClientSpy) = makeSut()
        expected(sut, completeWith: .failure(.unexpected)) {
            httpClientSpy.completeWithError(.noConnectivity)
        }
    }
    
    func test_login_should_complete_with_user_if_client_complete_with_valid_data() throws {
        let (sut, httpClientSpy) = makeSut()
        let expectedUser = makeUserLoginModel()
        expected(sut, completeWith: .success(expectedUser)) {
            httpClientSpy.completeWithData(expectedUser.toData()!)
        }
    }
        
    func test_login_should_complete_with_error_if_client_complete_with_invalid_data() throws {
        let (sut, httpClientSpy) = makeSut()
        expected(sut, completeWith: .failure(.unexpected)) {
            httpClientSpy.completeWithData(makeInvalidDate())
        }
    }
    
    func test_login_should_not_complete_if_sut_has_been_deallocated() throws {
        let httpClientSpy = HttpClientSpy()
        var sut: RemoteUserLogin? = RemoteUserLogin(url: makeURL(), httpClient: httpClientSpy)
        var result: Result<UserLoginModel, DomainError>?
        sut?.login(userSignBody: makeUserSignBody()) { result = $0 }
        sut = nil
        httpClientSpy.completeWithError(.noConnectivity)
        XCTAssertNil(result)
    }
}

extension RemoteUserLoginTests {
    
    func makeSut(url: URL = URL(string: "http://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteUserLogin, httpClientSpy: HttpClientSpy) {
        let httpClientSpy = HttpClientSpy()
        let sut = RemoteUserLogin(url: url, httpClient: httpClientSpy)
        checkMemoryLeak(for: sut, file: file, line: line)
        checkMemoryLeak(for: httpClientSpy, file: file, line: line)
        return (sut, httpClientSpy)
    }

    func expected(_ sut: RemoteUserLogin, completeWith expectedResult: Result<UserLoginModel, DomainError>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "waiting")
        sut.login(userSignBody: makeUserSignBody()) { receivedResult in
            switch (expectedResult, receivedResult) {
            case (.failure(let expectedError), .failure(let receivedError)): XCTAssertEqual(expectedError, receivedError, file: file, line: line)
            case (.success(let expectedUser), .success(let receivedUser)): XCTAssertEqual(expectedUser, receivedUser, file: file, line: line)
            default: XCTFail("Expected \(expectedResult) received \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1)
    }
}
