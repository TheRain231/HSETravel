import CoreData
import Foundation
import Logging

protocol FavoritesRepositoryProtocol {
    func fetchFavorites() -> [FavoriteCountry]
    func contains(country: Country) -> Bool
    func add(country: Country) throws
    func remove(id: String) throws
    func clear() throws
}

// CoreData entity wrapper
final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let ctx: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        ctx = context
    }

    func fetchFavorites() -> [FavoriteCountry] {
        logger.info("FavoritesRepository: fetch favorites")
        let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteCountry")
        do {
            let objs = try ctx.fetch(req)
            return objs.compactMap { obj in
                guard let id = obj.value(forKey: "id") as? String else { return nil }
                let name = obj.value(forKey: "name") as? String
                let capital = obj.value(forKey: "capital") as? String
                let population = obj.value(forKey: "population") as? Int64 ?? 0
                let flagURL = obj.value(forKey: "flagURL") as? String
                return FavoriteCountry(id: id, name: name, capital: capital, population: Int(population), flagURL: flagURL.flatMap(URL.init))
            }
        } catch {
            logger.logError(error, message: "Failed to fetch favorites")
            return []
        }
    }

    func add(country: Country) throws {
        logger.info("FavoritesRepository: add country", metadata: ["country": "\(country.displayName)"])
        guard let id = country.favoriteID else { return }
        let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteCountry")
        req.predicate = NSPredicate(format: "id == %@", id)
        req.fetchLimit = 1

        let ent = try ctx.fetch(req).first ?? NSEntityDescription.insertNewObject(forEntityName: "FavoriteCountry", into: ctx)
        ent.setValue(id, forKey: "id")
        ent.setValue(country.displayName, forKey: "name")
        ent.setValue(country.capitalName, forKey: "capital")
        ent.setValue(Int64(country.population ?? 0), forKey: "population")
        ent.setValue(country.flagURL?.absoluteString, forKey: "flagURL")
        try ctx.save()
    }

    func contains(country: Country) -> Bool {
        guard let id = country.favoriteID else { return false }
        let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteCountry")
        req.predicate = NSPredicate(format: "id == %@", id)
        req.fetchLimit = 1
        do {
            return try ctx.count(for: req) > 0
        } catch {
            logger.logError(error, message: "Failed to check favorite")
            return false
        }
    }

    func remove(id: String) throws {
        logger.info("FavoritesRepository: remove country", metadata: ["id": "\(id)"])
        let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteCountry")
        req.predicate = NSPredicate(format: "id == %@", id)
        let objs = try ctx.fetch(req)
        for o in objs {
            ctx.delete(o)
        }
        try ctx.save()
    }

    func clear() throws {
        logger.info("FavoritesRepository: clear favorites")
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteCountry")
        let del = NSBatchDeleteRequest(fetchRequest: req)
        try ctx.execute(del)
        try ctx.save()
    }
}

struct FavoriteCountry: Hashable {
    let id: String
    let name: String?
    let capital: String?
    let population: Int?
    let flagURL: URL?
}

extension Country {
    var favoriteID: String? {
        codeAlpha3 ?? displayName.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }
}
