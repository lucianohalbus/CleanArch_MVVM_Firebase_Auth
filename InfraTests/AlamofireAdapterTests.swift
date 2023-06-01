//

import XCTest
import Data
import Alamofire

class AlamofireAdapter {
    private let session: Session
    
    init(session: Session = .default) {
        self.session = session
    }
    
    func post(to url: URL, with data: Data?) {
        session.request(url, method: .post, parameters: data?.toJson(), encoding: JSONEncoding.default).resume()
    }
}

class AlamofireAdapterTests: XCTestCase {

    func test_post_should_make_request_with_valid_url_and_method() {
        let url = makeURL()
        testRequestFor(url: url, data: makeValidDate()) { request in
            XCTAssertEqual(url, request.url)
            XCTAssertEqual("POST", request.httpMethod)
            XCTAssertNotNil(request.httpBodyStream)
        }
    }
    
    func test_post_should_make_request_with_no_data() {
        testRequestFor(data: nil) { request in
            XCTAssertNil(request.httpBodyStream)
        }
    }
}

extension AlamofireAdapterTests {
    func makeSut( file: StaticString = #file, line: UInt = #line) -> AlamofireAdapter {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [UrlProtocolStrub.self]
        let session = Session(configuration: configuration)
        let sut = AlamofireAdapter(session: session)
        checkMemoryLeak(for: sut, file: file, line: line)
        return sut
    }
    
    func testRequestFor(url: URL = makeURL(), data: Data?, action: @escaping (URLRequest) -> Void) {
        let sut = makeSut()
        sut.post(to: url, with: data)
        let exp = expectation(description: "waiting")
        UrlProtocolStrub.observeRequest { request in
            action(request)
            exp.fulfill()
        }
        wait(for:  [exp], timeout: 1)
    }
}

class UrlProtocolStrub: URLProtocol {
    static var emit: ((URLRequest) -> Void)?
    static func observeRequest(completion: @escaping (URLRequest) -> Void) {
        UrlProtocolStrub.emit = completion
        
    }
    
    override open class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override open func startLoading() {
        UrlProtocolStrub.emit?(request)
    }
    
    override open func stopLoading() {
        
    }

}