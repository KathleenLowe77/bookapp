import Foundation
import ImageIO

struct EXIFResult {
    let description: String?
}

enum ImageEXIFFetcher {
    /// Downloads the image data and reads EXIF/TIFF Image Description.
    static func fetchDescription(from url: URL) async -> EXIFResult {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
                return EXIFResult(description: nil)
            }
            guard let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else {
                return EXIFResult(description: nil)
            }
            // TIFF dictionary usually holds "ImageDescription"
            let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            let exifDict = props[kCGImagePropertyExifDictionary] as? [CFString: Any]

            let tiffDesc = tiff?[kCGImagePropertyTIFFImageDescription] as? String
            let exifUserComment = exifDict?[kCGImagePropertyExifUserComment] as? String

            let desc = (tiffDesc?.isEmpty == false ? tiffDesc : nil) ??
                       (exifUserComment?.isEmpty == false ? exifUserComment : nil)
            return EXIFResult(description: desc)
        } catch {

            return EXIFResult(description: nil)
        }
    }
}
