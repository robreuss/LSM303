import Foundation
import SwiftyGPIO

let LSM303_ADDRESS_ACCEL = (0x32 >> 1)         // 0011001x
let LSM303_ADDRESS_MAG   = (0x3C >> 1)         // 0011110x
let LSM303_ID            = (0b11010100)

public enum AccelRegisters:UInt8 {
        case CTRL_REG1_A     = 0x20 // 00000111   rw
        case CTRL_REG2_A     = 0x21 // 00000000   rw
        case CTRL_REG3_A     = 0x22 // 00000000   rw
        case CTRL_REG4_A     = 0x23 // 00000000   rw
        case CTRL_REG5_A     = 0x24 // 00000000   rw
        case CTRL_REG6_A     = 0x25 // 00000000   rw
        case REFERENCE_A     = 0x26 // 00000000   r
        case STATUS_REG_A    = 0x27 // 00000000   r
        case OUT_X_L_A       = 0x28
        case OUT_X_H_A       = 0x29
        case OUT_Y_L_A       = 0x2A
        case OUT_Y_H_A       = 0x2B
        case OUT_Z_L_A       = 0x2C
        case OUT_Z_H_A       = 0x2D
        case FIFO_CTRL_REG_A = 0x2E
        case FIFO_SRC_REG_A  = 0x2F
        case INT1_CFG_A      = 0x30
        case INT1_SOURCE_A   = 0x31
        case INT1_THS_A      = 0x32
        case INT1_DURATION_A = 0x33
        case INT2_CFG_A      = 0x34
        case INT2_SOURCE_A   = 0x35
        case INT2_THS_A      = 0x36
        case INT2_DURATION_A = 0x37
        case CLICK_CFG_A     = 0x38
        case CLICK_SRC_A     = 0x39
        case CLICK_THS_A     = 0x3A
        case TIME_LIMIT_A    = 0x3B
        case TIME_LATENCY_A  = 0x3C
        case TIME_WINDOW_A   = 0x3D
}

public enum AccelScale:UInt8 {
        case G2  = 0b00000000 // Max is 2G
        case G4  = 0b00010000 // .. 4G
        case G8  = 0b00100000 // .. 8G
        case G16 = 0b00110000 // .. 16G
}

public enum MagRegisters : UInt8 {
        case CRA_REG_M         = 0x00
        case CRB_REG_M         = 0x01
        case MR_REG_M          = 0x02
        case OUT_X_H_M         = 0x03
        case OUT_X_L_M         = 0x04
        case OUT_Z_H_M         = 0x05
        case OUT_Z_L_M         = 0x06
        case OUT_Y_H_M         = 0x07
        case OUT_Y_L_M         = 0x08
        case SR_REG_Mg         = 0x09
        case IRA_REG_M         = 0x0A
        case IRB_REG_M         = 0x0B
        case IRC_REG_M         = 0x0C
        case TEMP_OUT_H_M      = 0x31
        case TEMP_OUT_L_M      = 0x32
}

public enum MagGain : UInt8 {
        case GAIN_1_3                    = 0x20 // +/- 1.3
        case GAIN_1_9                    = 0x40 // +/- 1.9
        case GAIN_2_5                    = 0x60 // +/- 2.5
        case GAIN_4_0                    = 0x80 // +/- 4.0
        case GAIN_4_7                    = 0xA0 // +/- 4.7
        case GAIN_5_6                    = 0xC0 // +/- 5.6
        case GAIN_8_1                    = 0xE0 // +/- 8.1
}

public enum MagRate : UInt8 {
    case LSM303_MAGRATE_0_7                        = 0x00  // 0.75 Hz
    case LSM303_MAGRATE_1_5                        = 0x01  // 1.5 Hz
    case LSM303_MAGRATE_3_0                        = 0x62  // 3.0 Hz
    case LSM303_MAGRATE_7_5                        = 0x03  // 7.5 Hz
    case LSM303_MAGRATE_15                         = 0x04  // 15 Hz
    case LSM303_MAGRATE_30                         = 0x05  // 30 Hz
    case LSM303_MAGRATE_75                         = 0x06  // 75 Hz
    case LSM303_MAGRATE_220                        = 0x07   // 200 Hz
}

public struct AccelData {
        public var x, y, z : Float
}

public struct MagData {
        public var x, y, z : Float
}

public class LSM303 {
        var i2c : I2CInterface
        public var accel : AccelData = AccelData(x: 0, y: 0, z: 0)
        public var mag   : MagData   = MagData(x: 0, y: 0, z: 0)
        var magGain : MagGain = MagGain.GAIN_1_3
        var accScale : AccelScale = AccelScale.G2
        var magRate : MagRate = MagRate.LSM303_MAGRATE_0_7

        public convenience init() {self.init(for:.RaspberryPi3)}
        public init(for board: SupportedBoard) {
                let i2cs = SwiftyGPIO.hardwareI2Cs(for:board)!
                self.i2c = i2cs[1] // not sure what i2cs[0] is ...
                // Enable the accelerometer
                i2c.writeByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.CTRL_REG1_A.rawValue, value: 0x27);
                // Enable the magnetometer
                i2c.writeByte(LSM303_ADDRESS_MAG, command: MagRegisters.MR_REG_M.rawValue, value: 0x00);

                accel = AccelData(x: 0, y: 0, z: 0)
                mag   = MagData(x: 0, y: 0, z: 0)
        }

        public func read() {
                // Read acceleration
		let xlo : UInt8 = i2c.readByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.OUT_X_L_A.rawValue); // Wire.read();
                let xhi : UInt8 = i2c.readByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.OUT_X_H_A.rawValue); // Wire.read();
                let ylo : UInt8 = i2c.readByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.OUT_Y_L_A.rawValue); // Wire.read();
                let yhi : UInt8 = i2c.readByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.OUT_Y_H_A.rawValue); // Wire.read();
                let zlo : UInt8 = i2c.readByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.OUT_Z_L_A.rawValue); // Wire.read();
                let zhi : UInt8 = i2c.readByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.OUT_Z_H_A.rawValue); // Wire.read();
                
		var g : Float = 1000.0
                switch (self.accScale) {
                        case .G2  : g =  1000.0
                        case .G4  : g =  2000.0
                        case .G8  : g =  4000.0
                        case .G16 : g = 12000.0
                }
                accel.x = Float(((Int16(xhi) << 8) | Int16(xlo)) >> 4) / g
                accel.y = Float(((Int16(yhi) << 8) | Int16(ylo)) >> 4) / g
                accel.z = Float(((Int16(zhi) << 8) | Int16(zlo)) >> 4) / g
		
		// Read magnetometer
                i2c.writeByte(LSM303_ADDRESS_MAG, value: MagRegisters.OUT_X_H_M.rawValue)
                let axlo : UInt8 = i2c.readByte(LSM303_ADDRESS_MAG, command: MagRegisters.OUT_X_L_M.rawValue); // Wire.read();
                let axhi : UInt8 = i2c.readByte(LSM303_ADDRESS_MAG, command: MagRegisters.OUT_X_H_M.rawValue); // Wire.read();
                let aylo : UInt8 = i2c.readByte(LSM303_ADDRESS_MAG, command: MagRegisters.OUT_Y_L_M.rawValue); // Wire.read();
                let ayhi : UInt8 = i2c.readByte(LSM303_ADDRESS_MAG, command: MagRegisters.OUT_Y_H_M.rawValue); // Wire.read();
                let azlo : UInt8 = i2c.readByte(LSM303_ADDRESS_MAG, command: MagRegisters.OUT_Z_L_M.rawValue); // Wire.read();
                let azhi : UInt8 = i2c.readByte(LSM303_ADDRESS_MAG, command: MagRegisters.OUT_Z_H_M.rawValue); // Wire.read();
                
		var mxy : Float = 1.0
		var mz  : Float = 1.0
		switch (self.magGain) {
			case .GAIN_1_3 : mxy = 1100.0; mz = 980.0 
                        case .GAIN_1_9 : mxy =  855.0; mz = 760.0
                        case .GAIN_2_5 : mxy =  670.0; mz = 600.0
                        case .GAIN_4_0 : mxy =  450.0; mz = 400.0
                        case .GAIN_4_7 : mxy =  400.0; mz = 355.0
                        case .GAIN_5_6 : mxy =  330.0; mz = 295.0
                        case .GAIN_8_1 : mxy =  230.0; mz = 105.0
		}
            /*
                mag.x = Float((Int16(axhi) << 8) | Int16(axlo)) / mxy
                mag.y = Float((Int16(ayhi) << 8) | Int16(aylo)) / mxy
                mag.z = Float((Int16(azhi) << 8) | Int16(azlo)) / mz
 */
            mag.x = Float((Int16(axhi) << 8) | Int16(axlo))
            mag.y = Float((Int16(ayhi) << 8) | Int16(aylo))
            mag.z = Float((Int16(azhi) << 8) | Int16(azlo)) 
        }

        public func setMagGain(gain: MagGain) {
                self.magGain = gain
                i2c.writeByte(LSM303_ADDRESS_MAG, command: MagRegisters.CRB_REG_M.rawValue, value: gain.rawValue)
        }

        public func setAccScale(scale: AccelScale) {
                self.accScale = scale
                i2c.writeByte(LSM303_ADDRESS_ACCEL, command: AccelRegisters.CTRL_REG4_A.rawValue, value: scale.rawValue)
        }
    
        public func setMagRate(rate: MagRate) {
            self.magRate = rate
            let value = (rate.rawValue & 0x07) << 2
            i2c.writeByte(LSM303_ADDRESS_MAG, command: MagRegisters.CRA_REG_M.rawValue, value: value)
            
        }
}
