//
//  SpreadsheetGrammar.swift
//  COSC346 Assignment 1
//
//  Created by David Eyers on 24/07/17.
//  Copyright © 2017 David Eyers. All rights reserved.
//

import Foundation


/// The spreadsheet is represented using a dictionary data structure. The keys are the cells and the values are the contents
//  (expressions or values) inside the cells. The contents are strings to start with and then integers are typecasted to 
//  Int when necessary.

//var cells: [String:String] = [:]

var cell : Array<String> = Array()
var contents : Array<String> = Array()
var value : Array<Int> = Array()

extension String {
    
    // Removes whitespaces from a string and returns the new string
    func removeWhiteSpace() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
    // Function for checking whether a string matches the specified RegEx pattern. Returns true is matches, else returns false
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

/**
// Isn't used at the moment. 
// Returns the contents of the cell that we are searching for
func findCell(cell: String) -> String {
    return cells[cell]!
}
**/

// Finds the relative cell in the expression in the input using the regex. If no string in input matches
// the regex then the func returns nil
func findRelCell(input: String) -> String? {
    let pattern = "[\"r\"]([0-9]+)[\"c\"]([0-9]+)"
    
    let parts : [String] = input.removeWhiteSpace().components(separatedBy: "+")
    
    for part in parts {
        if part.matches(pattern) {
            let relCell = part
            return relCell
        }
    }
    return nil
}



/** The top-level GrammarRule.
 This GrammarRule handles Spreadsheet -> Expression | Epsilon
 */
class GRSpreadsheet : GrammarRule {
    let myAssign = GRAssignment()  // Call the assignment class to assign a value to a cell
    let myPrint = GRPrint()        // Call the print class to print the contents of a cell
    
    init(){
        super.init(rhsRules: [[myAssign], [myPrint], [Epsilon.theEpsilon]])
    }
}



// Used to input the expression. This is what will be assigned to a cell
class GRExpression : GrammarRule {
    let myNum = GRInteger()
    let myProdTerm = GRProductTerm()
    let exprTail = GRExpressionTail()
    let quotedString = GRQuotedString()

    init(){
        super.init(rhsRules: [[myNum,exprTail], [myProdTerm,exprTail], [quotedString]])
    }
    
    override func parse(input: String) -> String? {
        let trimmedInput = input.removeWhiteSpace()
        let rest = super.parse(input:trimmedInput)
        
        //if let str = trimmedInput as? [String] {
        
        if rest != nil {
            self.calculatedValue = myNum.calculatedValue! + exprTail.calculatedValue!
        }
        return rest
    }
}


// The remainder of the expression. Is recursive so it'll take in multiple values and operators
class GRExpressionTail : GrammarRule {
    let plus = GRLiteral(literal: "+")
    let myValue = GRValue()
    let myNum = GRInteger()
    var total = ""
    
    init(){
        super.init(rhsRules: [[plus,myValue], [Epsilon.theEpsilon]])
    }
    
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            // if the value of num is nil then return nil
            if(self.myValue.num.calculatedValue == nil) {
                return nil
            }
            // recursively calls the class until there is no more input to call on
            let tail = GRExpressionTail()
            
            // if tail has a value then add that to the total
            if(tail.parse(input: rest) == nil) {
                self.calculatedValue = myValue.num.calculatedValue!
            
            }
            else {
                total = tail.parse(input: rest)!
                
                if(tail.calculatedValue != nil) {
                    self.calculatedValue = myValue.num.calculatedValue! + tail.calculatedValue!
                }
            }
            return total
        }
        return nil
    }
}

/// Parses the first value in the input and calls ProductTermTail on the rest of the input
class GRProductTerm : GrammarRule {
    let myNum = GRValue()
    let myProdTermTail = GRProductTermTail()
    
    init(){
        super.init(rhsRule: [myNum, myProdTermTail])
    }
    
    override func parse(input: String) -> String? {
        let trimmedInput = input.removeWhiteSpace()
        let rest = super.parse(input: trimmedInput)
        
        if (rest != nil) {
            self.calculatedValue = myNum.num.calculatedValue! * myProdTermTail.calculatedValue!
        }
        return rest
    }
}


/// Is the rest of the input after the first product term
class GRProductTermTail : GrammarRule {
    let mult = GRLiteral(literal: "*")
    let myValue = GRValue()
    var total = ""
    
    init(){
        super.init(rhsRules: [[mult, myValue], [Epsilon.theEpsilon]])
    }
    
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            // if value of num is nil then return nil
            if(self.myValue.num.calculatedValue == nil) {
                return nil
            }
            // Recursively calls the class until there is no more input
            let tail = GRProductTermTail()
            
            // if tail has a value then add that to the total
            if(tail.parse(input: rest) == nil) {
                self.calculatedValue =  myValue.num.calculatedValue!
                return rest
            }
            else {
                total = tail.parse(input: rest)!
                
                if(tail.calculatedValue != nil) {
                    self.calculatedValue = self.myValue.num.calculatedValue! * tail.calculatedValue!
                }
            }
            return total
        }
        return nil
    }
}

/// Assigns the specified value or expression to the cell specified in the input
class GRAssignment: GrammarRule {
    let absoluteCell = GRAbsoluteCell()  // Absolute cell that we are assigning the expression/value to
    let literal = GRLiteral(literal: ":=")  // Symbol to separate the absCell and the expression
    let myExpr = GRExpression()  // Expression that will become the contents of the cell
    

    init(){
        super.init(rhsRule: [absoluteCell, literal, myExpr])
    }
    
    override func parse(input: String) -> String? {
        //print("gets here")
        if let rest = super.parse(input: input) {
            
            //print("entered loop")
            // Removes whitespace from the input
            let trimmedInput = input.removeWhiteSpace()
            
            // Splits the input into halves either side of the ":="
            let inputSplit : [String] = trimmedInput.components(separatedBy: ":=")
           
            
            cell.append(inputSplit[0])
            contents.append(inputSplit[1])
            value.append(myExpr.calculatedValue!)
            
            return rest
        }
        return nil
    }
}

// Class for referencing the cell that needs to be assigned a value
class GRAbsoluteCell : GrammarRule {
    let myCol = GRColumnLabel()
    let myRow = GRRowNumber()
    
    init(){
        super.init(rhsRule: [myCol, myRow])
    }
    
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input){
            return rest
        }
        return nil
    }
}

/**
/// Returns the relative cell to the current cell
class GRRelativeCell : GrammarRule {
    let myRow = GRLiteral(literal: "r")
    let myCol = GRLiteral(literal: "c")
    let rowNum = GRInteger()
    let colNum = GRInteger()
    
    init(){
        super.init(rhsRule: [myRow, rowNum, myCol, colNum])
    }
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            return rest
        }
        return nil
    }
} **/
/// Returns the specified relative cell of the current cell
class GRRelativeCell : GrammarRule {
    let myRow = GRLiteral(literal: "r")
    let myCol = GRLiteral(literal: "c")
    let rowNum = GRInteger()
    let colNum = GRInteger()
    
    init(){
        super.init(rhsRule: [myRow, rowNum, myCol, colNum])
    }
    
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            _ = findRelCell(input: input)
            
            return rest
        }
        return nil
    }
}

/// Prints out the contents of the specified cell
class GRPrint : GrammarRule {
    let printVal = GRLiteral(literal: "print_value")
    let printExpr = GRLiteral(literal: "print_expr")
    let myExpr = GRAbsoluteCell()
    
    init() {
        super.init(rhsRules: [[printVal, myExpr], [printExpr, myExpr]])
    }

    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            let parts : [String] = input.components(separatedBy: " ")
            
            
            if cell.contains(parts[1]) {
                var total = 0
                let index : Int = cell.index(of: (parts[1]))!
                // If else statement that covers the print_expr and print_value input.
                // Prints the expression that is in the cell
                if(parts[0] == "print_expr") {
                    print("Expression in cell ", parts[1], "is ", contents[index])
                }
                // Prints the value in the cell
                else if(parts[0] == "print_value") {
                    
                    //Checks for a plus (+) or a multiply (*) and applies the right calculations
                    if contents[index].matches("([0-9]+)[+]([0-9]+)") {
                        let expr : [String] = contents[index].components(separatedBy: "+")
                        for e in expr {
                            total += Int(e)!
                        }
                        print("Value of cell ", parts[1], "is ", total)
                    }
                    else if contents[index].matches("([0-9]+)[*]([0-9]+)") {
                        total = 1
                        let expr : [String] = contents[index].components(separatedBy: "*")
                        for e in expr {
                            total *= Int(e)!
                        }
                        print("Value of cell ", parts[1], "is ", total)
                    }
                }
            }
            return rest
        }
        return nil
    }
}

/// StringNoQuote with quotes around it for printing purposes
class GRQuotedString : GrammarRule {
    let quote = GRLiteral(literal: "\"")
    let string = GRStringNoQuote()
    
    init(){
        super.init(rhsRule: [quote, string, quote])
    }
    override func parse(input: String) -> String? {
        
        if input.matches("[\"][a-zA-z][\"]") {
            return input
        }
        else {
            return nil
        }
    }
}

/// Either a cellReference or a number representing the value
class GRValue : GrammarRule {
    let cellRef = GRCellReference()
    let num = GRInteger()
    
    init() {
        super.init(rhsRules: [[cellRef], [num]])
    }
}

/// Represents either the absolute or the relative cell 
class GRCellReference : GrammarRule {
    let abs = GRAbsoluteCell()
    let rel = GRRelativeCell()
    
    init() {
        super.init(rhsRules: [[abs], [rel]])
    }
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            return rest
        }
        return nil
    }
}
