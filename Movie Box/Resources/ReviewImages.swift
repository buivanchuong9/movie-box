import UIKit

/// Local copies of the intro artwork in `Resources/ReviewImages`.
enum ReviewImages {
    static let collage = [
        "dune", "oppenheimer", "interstellar", "inception",
        "the-dark-knight", "parasite", "spider-man-no-way-home", "everything-everywhere"
    ]
    static let upcoming = ["dune-part-two", "civil-war", "challengers"]
    static let popular = ["the-dark-knight", "the-godfather", "the-matrix"]
    static let fresh = ["dune", "oppenheimer", "spider-man-no-way-home"]
    static let actors: [(file: String, name: String)] = [
        ("timothee-chalamet", "Timothée Chalamet"),
        ("zendaya", "Zendaya"),
        ("cillian-murphy", "Cillian Murphy"),
        ("pedro-pascal", "Pedro Pascal"),
        ("robert-downey-jr", "Robert Downey Jr."),
        ("scarlett-johansson", "Scarlett Johansson"),
        ("tom-holland", "Tom Holland"),
        ("emma-stone", "Emma Stone")
    ]

    static func image(folder: String, name: String) -> UIImage? {
        let directories = [
            "Resources/ReviewImages/\(folder)",
            "ReviewImages/\(folder)",
            folder
        ]
        for directory in directories {
            if let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: directory),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return nil
    }
}
