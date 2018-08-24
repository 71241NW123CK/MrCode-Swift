//
//  MrCode.swift
//  MrCode
//
//  Created by Ryan Hiroaki Tsukamoto on 1/8/18.
//

import AVFoundation
import UIKit

public struct MrCode: Equatable {
    public struct FormatOption: OptionSet {
        public static let upce = FormatOption(rawValue: 1 << 0)
        public static let code39 = FormatOption(rawValue: 1 << 1)
        public static let code39Mod43 = FormatOption(rawValue: 1 << 2)
        public static let ean13 = FormatOption(rawValue: 1 << 3)
        public static let ean8 = FormatOption(rawValue: 1 << 4)
        public static let code93 = FormatOption(rawValue: 1 << 5)
        public static let code128 = FormatOption(rawValue: 1 << 6)
        public static let pdf417 = FormatOption(rawValue: 1 << 7)
        public static let qr = FormatOption(rawValue: 1 << 8)
        public static let aztec = FormatOption(rawValue: 1 << 9)
        public static let interleaved2of5 = FormatOption(rawValue: 1 << 10)
        public static let itf14 = FormatOption(rawValue: 1 << 11)
        public static let dataMatrix = FormatOption(rawValue: 1 << 12)
        public static let all: FormatOption = [.upce, .code39, .code39Mod43, .ean13, .ean8, .code93, .code128, .pdf417, .qr, .aztec, .interleaved2of5, .itf14, .dataMatrix]
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public func avMetadataObjectObjectTypeList() -> [AVMetadataObject.ObjectType] {
            var result: [AVMetadataObject.ObjectType] = []
            if contains(.upce) {
                result.append(.upce)
            }
            if contains(.code39) {
                result.append(.code39)
            }
            if contains(.code39Mod43) {
                result.append(.code39Mod43)
            }
            if contains(.ean13) {
                result.append(.ean13)
            }
            if contains(.ean8) {
                result.append(.ean8)
            }
            if contains(.code93) {
                result.append(.code93)
            }
            if contains(.code128) {
                result.append(.code128)
            }
            if contains(.pdf417) {
                result.append(.pdf417)
            }
            if contains(.qr) {
                result.append(.qr)
            }
            if contains(.aztec) {
                result.append(.aztec)
            }
            if contains(.interleaved2of5) {
                result.append(.interleaved2of5)
            }
            if contains(.itf14) {
                result.append(.itf14)
            }
            if contains(.dataMatrix) {
                result.append(.dataMatrix)
            }
            return result
        }
    }

    public enum Format {
        case upce
        case code39
        case code39Mod43
        case ean13
        case ean8
        case code93
        case code128
        case pdf417
        case qr
        case aztec
        case interleaved2of5
        case itf14
        case dataMatrix
        
        public var option: FormatOption {
            get {
                switch self {
                case .upce:
                    return .upce
                case .code39:
                    return .code39
                case .code39Mod43:
                    return .code39Mod43
                case .ean13:
                    return .ean13
                case .ean8:
                    return .ean8
                case .code93:
                    return .code93
                case .code128:
                    return .code128
                case .pdf417:
                    return .pdf417
                case .qr:
                    return .qr
                case .aztec:
                    return .aztec
                case .interleaved2of5:
                    return .interleaved2of5
                case .itf14:
                    return .itf14
                case .dataMatrix:
                    return .dataMatrix
                }
            }
        }
        
        public init?(avMetadataObjectObjectType: AVMetadataObject.ObjectType) {
            switch avMetadataObjectObjectType {
            case .upce:
                self = .upce
            case .code39:
                self = .code39
            case .code39Mod43:
                self = .code39Mod43
            case .ean13:
                self = .ean13
            case .ean8:
                self = .ean8
            case .code93:
                self = .code93
            case .code128:
                self = .code128
            case .pdf417:
                self = .pdf417
            case .qr:
                self = .qr
            case .aztec:
                self = .aztec
            case .interleaved2of5:
                self = .interleaved2of5
            case .itf14:
                self = .itf14
            case .dataMatrix:
                self = .dataMatrix
            default:
                return nil
            }
        }
    }
    
    public let format: Format
    public let value: String
    
    public static func ==(lhs: MrCode, rhs: MrCode) -> Bool {
        return lhs.format == rhs.format && lhs.value == rhs.value
    }

    public init?(avMetadataMachineReadableCodeObject: AVMetadataMachineReadableCodeObject) {
        guard
            let format = Format(avMetadataObjectObjectType: avMetadataMachineReadableCodeObject.type),
            let value = avMetadataMachineReadableCodeObject.stringValue
        else {
                return nil
        }
        self.format = format
        self.value = value
    }
}

public class MrCodeScanner: UIView {
    public struct Plugin {
        public let supportedFormats: MrCode.FormatOption
        public let predicate: ((String) -> Bool)?
        public let mrCodeFoundCompletion: ((MrCode) -> ())?
        public let mrCodeLostCompletion: (() -> ())?
        
        public func canBeUsedFor(mrCode: MrCode) -> Bool {
            if !supportedFormats.contains(mrCode.format.option) {
                return false
            }
            if let predicate = predicate {
                return predicate(mrCode.value)
            }
            return true
        }
        
        public init(supportedFormats: MrCode.FormatOption, predicate: ((String) -> Bool)?, mrCodeFoundCompletion: ((MrCode) -> ())?, mrCodeLostCompletion: (() -> ())?) {
            self.supportedFormats = supportedFormats
            self.predicate = predicate
            self.mrCodeFoundCompletion = mrCodeFoundCompletion
            self.mrCodeLostCompletion = mrCodeLostCompletion
        }
    }
    
    public var pluginChain: [Plugin] = [] {
        didSet {
            print("set plugin chain")
            setCaptureMetadataOutputMetadataObjectTypes()
        }
    }
    
    public var captureDevicePosition: AVCaptureDevice.Position = .back

    private let metadataQueue = DispatchQueue(label: "party.treesquaredcode.MrCode.Scanner")
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureMetadataOutput: AVCaptureMetadataOutput?
    private var currentMrCode: MrCode?
    private var currentPlugin: Plugin?
    private var isActive = false
    
    public func viewDidAppear() {
        if isActive {
            return
        }
        guard
            let captureDevice = AVCaptureDevice.devices(for: .video).first(where: { $0.position == self.captureDevicePosition }),
            let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            return
        }
        captureSession = AVCaptureSession()
        captureSession.addInput(captureDeviceInput)
        let captureMetadataOutput = AVCaptureMetadataOutput()
        self.captureMetadataOutput = captureMetadataOutput
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let videoPreviewLayer = videoPreviewLayer {
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer.frame = layer.bounds
            layer.addSublayer(videoPreviewLayer)
            captureSession.startRunning()
        }
        setCaptureMetadataOutputMetadataObjectTypes()
        isActive = true
    }
    
    public func viewWillDisappear() {
        if !isActive {
            return
        }
        if let videoPreviewLayer = videoPreviewLayer {
            videoPreviewLayer.removeFromSuperlayer()
            self.videoPreviewLayer = nil
            captureSession.stopRunning()
        }
        self.captureMetadataOutput = nil
        isActive = false
    }
    
    public func invalidateCurrentPlugin() {
        currentPlugin = nil
    }
    
    private func setCaptureMetadataOutputMetadataObjectTypes() {
        guard let captureMetadataOutput = captureMetadataOutput else {
            return
        }
        let options: MrCode.FormatOption = pluginChain.reduce([]) { $0.union($1.supportedFormats) }
        captureMetadataOutput.metadataObjectTypes = options.avMetadataObjectObjectTypeList()
    }
}

extension MrCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let metadataMachineReadableCodeObjectList = metadataObjects.flatMap { $0 as? AVMetadataMachineReadableCodeObject }
        guard
            let firstMetadataMachineReadableCodeObject = metadataMachineReadableCodeObjectList.first,
            let mrCode = MrCode(avMetadataMachineReadableCodeObject: firstMetadataMachineReadableCodeObject)
        else {
                currentMrCode = nil
                if let completion = currentPlugin?.mrCodeLostCompletion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
                currentPlugin = nil
                return
        }
        if let currentMrCode = currentMrCode, currentMrCode == mrCode {
            return
        }
        currentMrCode = mrCode
        var actionList: [() -> ()] = []
        if let completion = currentPlugin?.mrCodeLostCompletion {
            actionList.append(completion)
        }
        currentPlugin = pluginChain.first(where: { $0.canBeUsedFor(mrCode: mrCode) })
        if let completion = currentPlugin?.mrCodeFoundCompletion {
            actionList.append({ completion(mrCode) })
        }
        if !actionList.isEmpty {
            DispatchQueue.main.async {
                actionList.forEach { $0() }
            }
        }
    }
}
