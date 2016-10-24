//
//  ColorDB.swift
//  lazerbeamz
//
//  Created by kyb on 20/10/2016.
//  Copyright © 2016 Suborbital Softowrks Ltd. All rights reserved.
//

import Foundation
import sqlite3

class ColorDB {
    enum ColorDBError : Error {
        case SQLiteError(message: String)
        case DatabaseNotOpened
    }
    
    var db: OpaquePointer? = nil
    
    func open(filename: String) throws {
        if sqlite3_open(filename, &self.db) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw ColorDBError.SQLiteError(message: errorMessage)
        }
    }
    
    func insert(filename: String, colorset: ColorSet) throws {
        if self.db == nil {
            throw ColorDBError.DatabaseNotOpened
        }
    }
    
    func read(filename: String) throws  -> ColorSet? {
        if self.db == nil {
            throw ColorDBError.DatabaseNotOpened
        }
        
        return nil
    }
    
    func close() {
        sqlite3_close(self.db)
        self.db = nil
    }
}
