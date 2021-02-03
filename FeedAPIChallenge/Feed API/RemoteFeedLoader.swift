//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }
			switch result {
			case .success(let (data, response)):
				do {
					let items = try FeedMapper.map(data, response)
					completion(.success(items))
				} catch {
					completion(.failure(RemoteFeedLoader.Error.invalidData))
				}
			case .failure:
				completion(.failure(RemoteFeedLoader.Error.connectivity))
			}
		}
	}
}

private class FeedMapper {
	private struct Root: Decodable {
		let items: [Item]
	}
	
	private struct Item: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL
		
		var item: FeedImage {
			return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
		}
	}
	
	static var OK_200: Int { 200 }
	
	static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedImage] {
		guard response.statusCode == OK_200 else {
			throw RemoteFeedLoader.Error.invalidData
		}
		
		let root = try JSONDecoder().decode(Root.self, from: data)
		return root.items.map{ $0.item }
	}
}
