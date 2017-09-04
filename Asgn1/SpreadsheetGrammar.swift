//
//  SpreadsheetGrammar.swift
//  COSC346 Assignment 1
//
//  Skeleton code by David Eyers on 24/07/17. Final code by Oliver Westenra 04/09/17
//  Copyright © 2017 David Eyers. All rights reserved.
//

import Foundation


/** 
Cell values and expressions are added at the same time so the index of a cells value will be the index of the cell in the cells array
 **/
// Array of the cells that we have initialized
var cells : Array<String> = Array()
// Array of the expressions that are in each cell
var contents : Array<String> = Array()
// Array of the actual values that are in each cell
var value : Array<Int> = Array()


/** 
 Extends the String functionality to save rewriting code
**/
extension String {
    // Removes whitespaces from a string and returns the new string
    func removeWhiteSpace() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
    // Function for checking whether a string matches the specified RegEx pattern. Returns true if matches, else returns false
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

func calcValue(input: String) ->  Int{
    var total = 0
    if input.matches("([0-9]+)[+]([0-9]+)") {
        let expr : [String] = input.components(separatedBy: "+")
         
         for e in expr {
         total += Int(e)!
         }
        return total
    }
    else if input.matches("([0-9]+)[*]([0-9]+)") {
        if total == 0 {
            total = 1
        }
        let expr : [String] = input.components(separatedBy: "*")
         for e in expr {
         total *= Int(e)!
         }
        return total
    }
    else if input.matches("[0-9]") {
        return Int(input)!
    }
    return Int(input)!

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


/**
 Used to input the expression. This is what will be assigned to a cell
**/
class GRExpression : GrammarRule {
    let myProdTerm = GRProductTerm()
    let exprTail = GRExpressionTail()
    let quotedString = GRQuotedString()

    init(){
        super.init(rhsRules: [[myProdTerm,exprTail], [quotedString]])
    }
    
    override func parse(input: String) -> String? {
        let rest = super.parse(input: input)
        
        // Calls down through the classes ProdTerm -> Value to get the integer value and
        // brings it back up
        let prodTermValue = myProdTerm.calculatedValue
        
        //print("profterm:",prodTermValue)
        //print("exprtail:",exprTail.calculatedValue)
        
        if rest != nil {
            if prodTermValue != nil && exprTail.calculatedValue != nil {
                self.calculatedValue = prodTermValue! + exprTail.calculatedValue!
            }
            else if prodTermValue != nil && exprTail.calculatedValue == nil {
                self.calculatedValue = prodTermValue
            }
            return rest
        }
        return nil
    }
}

/**
 The remainder of the expression. Is recursive so it'll take in multiple values and operators
**/
class GRExpressionTail : GrammarRule {
    let plus = GRLiteral(literal: "+")
    let myProdTerm = GRProductTerm()
    var total = ""
    
    init(){
        super.init(rhsRules: [[plus,myProdTerm], [Epsilon.theEpsilon]])
    }
    
    override func parse(input: String) -> String? {
       
        if let rest = super.parse(input: input) {
            
            let prodTerm = myProdTerm.myValue.myInt.calculatedValue
            
            if rest == input {
                return rest
            }
            
            // recursively calls the class until there is no more input to call on
            let tail = GRExpressionTail()
            
            // if tail has a value then add that to the total
            if tail.parse(input: rest) == nil {
                self.calculatedValue = prodTerm!
            }
            else {
                total = tail.parse(input: rest)!
                
                if tail.calculatedValue != nil {
                    self.calculatedValue = prodTerm! + tail.calculatedValue!
                } else {
                    self.calculatedValue = prodTerm!
                }
            }
            return total
        }
        return nil
    }
}

/**
 Parses the first value in the input and calls ProductTermTail on the rest of the input
**/
class GRProductTerm : GrammarRule {
    let myValue = GRValue()
    let myProdTermTail = GRProductTermTail()
    
    init(){
        super.init(rhsRule: [myValue, myProdTermTail])
    }
    
    override func parse(input: String) -> String? {
        
        let rest = super.parse(input: input.removeWhiteSpace())
        
        
        // Created the variable so I didn't have to type it out all the time
        let value = myValue.myInt.calculatedValue
        
        if value != nil && myProdTermTail.calculatedValue != nil {
            self.calculatedValue = value! * myProdTermTail.calculatedValue!
        }
        else if value != nil && myProdTermTail.calculatedValue == nil {
            self.calculatedValue = value!
        }
        return rest
    }
}

/**
 Is the rest of the input after the first product term. Is recursive so will handle multiple values 
 and operators
**/
class GRProductTermTail : GrammarRule {
    let mult = GRLiteral(literal: "*")
    let myValue = GRValue()
    var total = ""
    
    init(){
        super.init(rhsRules: [[mult, myValue], [Epsilon.theEpsilon]])
    }
    
    override func parse(input: String) -> String? {
        
        if let rest = super.parse(input: input) {
            
            let val = myValue.myInt.calculatedValue
            
            // Base case. This will only fail when there is still more input to play with
            if(rest == input) {
                return input
            }
            // Recursively calls the class until there is no more input
            let tail = GRProductTermTail()
            
            // If we have reached the end of the tail then we stop the recursion
            if(tail.parse(input: rest) == nil) {
                self.calculatedValue =  val!
                return rest
            }
            // If there is still more stuff on the tail then keep going until we hit the end of input
            else {
                total = tail.parse(input: rest)!
                
                if(tail.calculatedValue != nil) {
                    self.calculatedValue = val! * tail.calculatedValue!
                }else{
                    self.calculatedValue = val!
                }
            }
            return total
        }
        return nil
    }
}

/**
 Assigns the specified value or expression to the cell absoluteCell
**/
class GRAssignment: GrammarRule {
    let absoluteCell = GRAbsoluteCell()
    let literal = GRLiteral(literal: ":=")
    let myExpr = GRExpression()
    

    init(){
        super.init(rhsRule: [absoluteCell, literal, myExpr])
    }
    
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            
            // Splits the input into halves either side of the ":="
            let inputSplit : [String] = input.removeWhiteSpace().components(separatedBy: ":=")
        
           
            // If the cell is already in the array then we alter its contents and value
            if cells.contains(inputSplit[0]) {
                let index = cells.index(of: inputSplit[0])
                contents[index!] = inputSplit[1]
                value[index!] = myExpr.calculatedValue!
            }
            // The cell is not in the array so we assign its contents and value in the
            // appropriate array
            else {
                cells.append(inputSplit[0])
                value.append(myExpr.calculatedValue!)
                contents.append(inputSplit[1])
            }
            
            return rest
        }
        return nil
    }
}

/**
 Class for referencing the cell that needs to be assigned a value
 eg. A1
**/
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
 Returns the specified relative cell of the current cell
 !Does not function as it should!
**/
class GRRelativeCell : GrammarRule {
    let myRow = GRLiteral(literal: "r")
    let myCol = GRLiteral(literal: "c")
    let rowNum = GRInteger()
    let colNum = GRInteger()
    
    init(){
        super.init(rhsRule: [myRow, rowNum, myCol, colNum])
    }
    
    override func parse(input: String) -> String? {
        // regex pattern to search for
        let pattern = "[\"r\"]([0-9]+)[\"c\"]([0-9]+)"
        
        // Splits the input into the parts that are to be added together
        let parts : [String] = input.removeWhiteSpace().components(separatedBy: "+")
            
        for part in parts {
            if part.matches(pattern) {
                let relCell = part
                return relCell
            }
        }
        return nil
    }
}

/**
 Prints out the contents of the specified cell
 Input will be either print_value or print_expr followed by an absoluteCell reference
 The class the prints out either the expression in the cell or the integer value in the cell
**/
class GRPrint : GrammarRule {
    let printVal = GRLiteral(literal: "print_value")
    let printExpr = GRLiteral(literal: "print_expr")
    let myAbsCell = GRAbsoluteCell()
    
    init() {
        super.init(rhsRules: [[printVal, myAbsCell], [printExpr, myAbsCell]])
    }

    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            
            // Creates an array of the parts of the input
            let parts : [String] = input.components(separatedBy: " ")
            
            // Check if the cell exists
            if cells.contains(parts[1]) {
                var total = 0
                let index : Int = cells.index(of: (parts[1]))!
                
                /**
                If else statement that covers the print_expr and print_value input.
                print_expr : Prints out the contents of the cell, eg. "string", 1+3*2
                print_value: Prints out the actual value that the expression represents
                **/
                // Prints the expression that is in the cell
                if(parts[0] == "print_expr") {
                    print("Expression in cell", parts[1], "is", contents[index])
                }
                    
                // Prints the value in the cell
                else if(parts[0] == "print_value") {
                    
                    // Checks if the contents is a string.
                    // If it is then it just prints out the string for that cell
                    if contents[index].matches("[\"]([a-zA-Z0-9]+)[\"]") {
                        print("Value of cell", parts[1], "is", contents[index])
                    }
                    // Checks if the input is adding the values
                    // If it is then it adds the values and adds the total to the value array
                    else if contents[index].matches("([0-9]+)[+]([0-9]+)") {
                        
                        let expr : [String] = contents[index].components(separatedBy: "+")
                            for e in expr {
                            total += Int(e)!
                        }
                        
                        value[index] = total
                        print("Value of cell", parts[1], "is", value[index])
                    }
                    // Checks if the input is multiplying the values
                    // If it is then it multiplies the values and adds the total to the value array
                    else if contents[index].matches("([0-9]+)[*]([0-9]+)") {
                        if total == 0 {
                            total = 1
                        }
                        
                        let expr : [String] = contents[index].components(separatedBy: "*")
                            for e in expr {
                            total *= Int(e)!
                        }
                        
                        value[index] = total
                        print("Value of cell", parts[1], "is", value[index])
                    }
                    // If none of the above are true then the value must just be a single
                    // integer, so adds this integer to the value array
                    else if contents[index].matches("[0-9]") {
                        print("Value of cell", parts[1], "is", value[index])
                    }
                }
                
            // If the cell has not been initialised then we give it a default value 0
            } else {
                cells.append(parts[1])
                contents.append("0")
                value.append(0)
            }
            return rest
        }
        return nil
    }
}

/**
 Used for assigning a string to a cell
 Input must be in the format "hello". In my test cases "covfefe" parses because it has quotemarks
 represented as "\"covfefe\""
 The next test case does not parse because it is "my name is oliver" which does not have explicit 
 quotemarks
 Uses the GRStringNoQuote token
**/
class GRQuotedString : GrammarRule {
    let quote = GRLiteral(literal: "\"")
    let string = GRStringNoQuote()
    
    init(){
        super.init(rhsRule: [quote, string, quote])
    }
    
    // Regex expression to confirm that the string is a quoted string and then returns it.
    override func parse(input: String) -> String? {
        if input.matches("[\"]([a-zA-Z]+)[\"]") {
            return input
        }
        else {
            return nil
        }
    }
}

/**
 Either a cellReference or a number representing the value
**/
class GRValue : GrammarRule {
    let cellRef = GRCellReference()
    let myInt = GRInteger()
    
    init() {
        super.init(rhsRules: [[cellRef], [myInt]])
    }

    // Returns the remainder of the input and parses the first section out to be used by other classes
    override func parse(input: String) -> String? {
        if let rest = super.parse(input: input) {
            if myInt.calculatedValue != nil {
                return rest
            }
        }
        return nil
    }
    
}

/**
 Represents either the absolute or the relative cell
**/
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
