import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}

    lazy var container: NSPersistentContainer = {
        // Create model programmatically so no .xcdatamodeld is required.
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "FavoriteCountry"
        entity.managedObjectClassName = "NSManagedObject"

        var props: [NSAttributeDescription] = []
        let idAttr = NSAttributeDescription(); idAttr.name = "id"; idAttr.attributeType = .stringAttributeType; idAttr.isOptional = false
        let nameAttr = NSAttributeDescription(); nameAttr.name = "name"; nameAttr.attributeType = .stringAttributeType; nameAttr.isOptional = true
        let capitalAttr = NSAttributeDescription(); capitalAttr.name = "capital"; capitalAttr.attributeType = .stringAttributeType; capitalAttr.isOptional = true
        let populationAttr = NSAttributeDescription(); populationAttr.name = "population"; populationAttr.attributeType = .integer64AttributeType; populationAttr.isOptional = true
        let flagAttr = NSAttributeDescription(); flagAttr.name = "flagURL"; flagAttr.attributeType = .stringAttributeType; flagAttr.isOptional = true
        props = [idAttr, nameAttr, capitalAttr, populationAttr, flagAttr]
        entity.properties = props
        model.entities = [entity]

        let container = NSPersistentContainer(name: "HSETravelModel", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("CoreData failed to load: \(error)") }
        }
        return container
    }()

    var context: NSManagedObjectContext { container.viewContext }

    func saveContext() {
        let ctx = context
        if ctx.hasChanges {
            do { try ctx.save() } catch { print("CoreData save error: \(error)") }
        }
    }
}
