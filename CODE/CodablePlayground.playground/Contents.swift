import AppKit
import Foundation

//
// MARK: - Entidades
//

// Errores personalizados
public enum VersionError: Error
{
    case jsonEncoding
    case jsonDecoding
    case httpError
}

// Arquitecturas
public enum Platform: String, Codable
{
    case powerPC = "PowerPC"
    case intel32 = "x86"
    case intel64 = "x86-64"
}

// Lenguajes de desarrollo
public enum Languages: String, Codable
{
    case c = "C"
    case cPlusPlus = "C++"
    case objectiveC = "Objective-C"
    case swift = "Swift"
}

// Versiones de los SO
public enum Release
{
    ///
    case initial(os: Int, version: Int)
    ///
    case latest(os: Int, version: Int, update: Int)
}

// Codable para Release
extension Release: Codable
{
    private enum CodingKeys: String, CodingKey
    {
        case initial
        case latest
    }
    
    private struct HelperInitial: Codable
    {
        internal var os: Int
        internal var version: Int
    }
    
    private struct HelperLatest:  Codable
    {
        internal var os: Int
        internal var version: Int
        internal var update: Int
    }
    
    /// Para decodificar un JSON
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let initialValue = try container.decodeIfPresent(Release.HelperInitial.self, forKey: .initial)
        {
            self = .initial(os: initialValue.os, version: initialValue.version)
        }
        else if let latestValue = try container.decodeIfPresent(Release.HelperLatest.self, forKey: .latest)
        {
            self = .latest(os: latestValue.os, version: latestValue.version, update: latestValue.update)
        }
        else
        {
            throw VersionError.jsonDecoding
        }
    }
    
    /// Para codificar la enumeración en un JSON
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self
        {
            case .initial(let os, let version):
                let initialStruct = HelperInitial(os: os, version: version)
                try container.encode(initialStruct, forKey: .initial)
            
            case .latest(let os, let version, let update):
                let latestStruct = HelperLatest(os: os, version: version, update: update)
                try container.encode(latestStruct, forKey: .latest)
        }
    }
}

// CustomStringConvertible para Release

extension Release: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
            case .initial(let os, let version):
                return "\(os).\(version)"
            case .latest(let os, let version, let update):
                return "\(os).\(version).\(update)"
        }
    }
}

// Datos de una versión de macOS
public struct Version: Codable
{
    public private(set) var codeName: String
    public private(set) var versionDescription: String
    public private(set) var wikipediaURL: URL
    public private(set) var releaseAt: Date
    public private(set) var storeAvailable: Bool
    public private(set) var platforms: [Platform]
    public private(set) var developmentLanguages: [Languages]
    public private(set) var firstRelase: Release
    public private(set) var lastRelease: Release
    public private(set) var logoData: Data
    
    //
    // MARK: - Codable
    //
    
    private enum CodingKeys: String, CodingKey
    {
        case codeName = "name"
        case versionDescription = "description"
        case wikipediaURL = "wikipedia_url"
        case releaseAt = "release_date"
        case storeAvailable = "mac-app-store_available"
        case platforms
        case developmentLanguages = "development_languages"
        case firstRelase = "first_release"
        case lastRelease = "last_release"
        case logoData = "logo_data"
    }
}

// Extension para formatear fechas
extension DateFormatter
{
    public static var versionFormatter: DateFormatter
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/M/yyyy"
        
        return formatter
    }
}

//
// JSON -> [Version]
//

var versions: [Version]?

if let jsonURL = URL(string: "https://raw.githubusercontent.com/fitomad/Desappstre-Codable/master/JSON/osx-macos.json"),
   let data = try? Data(contentsOf: jsonURL)
{
    // Creamos el decodificador JSON
    let decoder = JSONDecoder()
    // Establecemos el formato de fechas
    decoder.dateDecodingStrategy = .formatted(DateFormatter.versionFormatter)
    
    do
    {
        // Obtenemos el array de Version
        versions = try decoder.decode([Version].self, from: data)
        // Lo recorremos
        versions?.forEach({
            print("\($0.codeName). Última versión \($0.lastRelease)")
        })
    }
    catch let jsonError
    {
        print(jsonError.localizedDescription)
    }
}

//
// Version -> JSON
//

if let versions = versions
{
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(DateFormatter.versionFormatter)
    
    if let version = versions.filter({ $0.codeName == "Mojave" }).first
    {
        let logo = NSImage(data: version.logoData)
        let data = try? encoder.encode(version)
        dump(data)
    }
}


