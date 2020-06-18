import Foundation

final class RESTTransactionService: TransactionService {

    private let client: Client

    init(client: Client) {
        self.client = client
    }

    init(tink: Tink) {
        self.client = tink.client
    }

    @discardableResult
    func transactions(
        query: TransactionsQuery,
        offset: Int? = nil,
        completion: @escaping (Result<([Transaction], Bool), Error>) -> Void
    ) -> Cancellable? {
        var searchQuery = RESTSearchQuery()

        searchQuery.limit = query.limit
        searchQuery.offset = offset
        searchQuery.accounts = query.accountIDs.isEmpty ? nil : query.accountIDs.map { $0.value }
        searchQuery.categories = query.categoryIDs.isEmpty ? nil : query.categoryIDs.map { $0.value }
        searchQuery.startDate = query.dateInterval?.start
        searchQuery.endDate = query.dateInterval?.end
        // FIXME: We have to always fetch with `includeUpcoming` set to `true` since backend will not include todays transactions until noon when a transaction has changed from being upcoming.
        searchQuery.includeUpcoming = true
        searchQuery.queryString = query.query
        searchQuery.order = RESTOrderType(transactionQueryOrder: query.order)
        searchQuery.sort = RESTSortType(transactionQuerySort: query.sort)

        let bodyEncoder = JSONEncoder()
        bodyEncoder.dateEncodingStrategy = .custom({ (date, encoder) in
            var container = encoder.singleValueContainer()
            try container.encode(Int(date.timeIntervalSince1970 * 1000))
        })
        let body = try! bodyEncoder.encode(searchQuery)

        let request = RESTResourceRequest<RESTSearchResponse>(path: "/api/v1/search", method: .post, body: body, contentType: .json) { result in
            let mapped = result.map { transactionsResponse -> ([Transaction], Bool) in
                let transactions = transactionsResponse.results.compactMap({$0.transaction.flatMap(Transaction.init)})
                let hasMore = transactions.count >= (query.limit ?? 50)
                return (transactions, hasMore)
            }
            completion(mapped)
        }

        return client.performRequest(request)
    }

    @discardableResult
    func categorize(
        _ transactionIDs: [String],
        as newCategoryID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {

        let listRequest = RESTCategorizeTransactionsListRequest(
            categorizationList: [
                RESTCategorizeTransactionsRequest(
                    categoryId: newCategoryID,
                    transactionIds: transactionIDs
                )
            ]
        )

        let request = RESTSimpleRequest(path: "/api/v1/transactions/categorize-multiple", method: .put, body: listRequest, contentType: .json) { result in
            let mapped = result.map { (_) -> Void in
                return
            }
            completion(mapped)
        }

        return client.performRequest(request)
    }

    @discardableResult
    func transactionsSimilar(
        to transactionID: String,
        ifCategorizedAs categoryID: String,
        completion: @escaping (Result<[Transaction], Error>) -> Void
    ) -> Cancellable? {

        let request = RESTResourceRequest<RESTSimilarTransactionsResponse>(path: "/api/v1/transactions/\(transactionID)/similar", method: .get, contentType: nil, parameters: [.init(name: "categoryId", value: categoryID)]) { result in
            let mapped = result.map { $0.transactions.compactMap(Transaction.init) }
            completion(mapped)
        }

        return client.performRequest(request)
    }
}
