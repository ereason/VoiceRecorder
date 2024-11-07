//
//  PdfManager.swift
//  VoiceRecorder
//
//  Created by george on 22.10.2024.
//

import PDFKit
import AVFoundation

class PdfManager {
    let pageWidth = 9 * 100.0
    let pageHeight = 12 * 100.0
    lazy var pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
    lazy var graphRect = CGRect(x: 0.0, y: pageRect.midY, width: pageWidth, height: pageRect.height / 2)
    let audioFileUrl: URL
    
    init(audioFileUrl: URL) {
        self.audioFileUrl = audioFileUrl
    }
    
    func createDocument() -> Data {
        
        let format = UIGraphicsPDFRendererFormat()
        
        let pdfMetaData = [
            kCGPDFContextCreator: "George",
            kCGPDFContextAuthor: "George"
        ]
        
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let attributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 72)
            ]
            
            let text = "Page 1 Wave charts:"
            text.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
            
            generateWaveImage(
                imageSize: .init(width: graphRect.width, height: graphRect.height),
                strokeColor: .red,
                backgroundColor: .white,
                waveWidth: 1.0,
                waveSpacing: 10
            ) { image in
                
                image?.draw(at: self.graphRect.origin)
            }
        }
        
        return data
    }
}

extension PdfManager {
    func readBuffer(completion: @escaping (_ wave:UnsafeBufferPointer<Float>?)->Void)  {
        guard let file = try? AVAudioFile(forReading: audioFileUrl) else {
            completion(nil)
            return
        }
        let audioFormat = file.processingFormat
        let audioFrameCount = UInt32(file.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount) else {
            return completion(UnsafeBufferPointer<Float>(_empty: ()))
        }
        
        do {
            try file.read(into: buffer)
        } catch {
            print(error)
        }
        
        let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
        
        completion(floatArray)
    }
    
    func generateWaveImage(
        imageSize: CGSize,
        strokeColor: UIColor,
        backgroundColor: UIColor,
        waveWidth: CGFloat,
        waveSpacing: CGFloat,
        completion: @escaping (_ image: UIImage?) -> Void
    ) {
        readBuffer { samples in
            guard let samples = samples else {
                completion(nil)
                return
            }
            
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            guard let context: CGContext = UIGraphicsGetCurrentContext() else {
                completion(nil)
                return
            }
            
            let middleY = imageSize.height / 2
            
            context.setFillColor(backgroundColor.cgColor)
            context.setAlpha(1.0)
            context.fill(CGRect(origin: .zero, size: imageSize))
            context.setLineWidth(waveWidth)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            
            let maxAmplitude = samples.max() ?? 0
            let heightNormalizationFactor = Float(imageSize.height) / maxAmplitude / 2
            
            var x: CGFloat = 0.0
            let samplesCount = samples.count
            let sizeWidth = 100
            var index = 0
            var sampleAtIndex = samples.item(at: index * samplesCount / sizeWidth)
            
            while sampleAtIndex != nil {
                
                sampleAtIndex = samples.item(at: index * samplesCount / sizeWidth)
                let normalizedSample = CGFloat(sampleAtIndex ?? 0) * CGFloat(heightNormalizationFactor)
                let waveHeight = normalizedSample * middleY
                
                context.move(to: CGPoint(x: x, y: middleY - waveHeight))
                context.addLine(to: CGPoint(x: x, y: middleY + waveHeight))
                
                x += waveSpacing + waveWidth
                
                index += 1
            }
            
            context.setStrokeColor(strokeColor.cgColor)
            context.strokePath()
            
            guard let soundWaveImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                completion(nil)
                return
            }
            
            UIGraphicsEndImageContext()
            completion(soundWaveImage)
        }
    }
}
