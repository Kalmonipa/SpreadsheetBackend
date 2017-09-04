//
//  main.swift
//  COSC346 Assignment 1
//
//  Created by David Eyers on 24/07/17.
//  Copyright © 2017 David Eyers. All rights reserved.
//
//  Some basic tests that aim to assist understanding of the GrammarRules.
//  As noted, this code should be replaced by you doing something better.

import Foundation

// If command line arguments are given, then try to interpret them as filenames, reading them and parsing them in sequence.
// Note that output requested in the specification should be generated during the parsing process: for example, successfully parsing a Print will produce output. Your code should not produce any other output when parsing a string read from a file.
if CommandLine.arguments.count>1 {
    var filenames = CommandLine.arguments
    filenames.removeFirst() // first argument is the name of the executable
    
    func stderrPrint(_ message:String) {
        let stderr = FileHandle.standardError
        stderr.write(message.data(using: String.Encoding.utf8)!)
    }
    
    for filename in filenames {
        do {
            let filecontents : String = try String.init(contentsOfFile: filename)
            let aGRSpreadsheet = GRSpreadsheet()
            if let remainder = aGRSpreadsheet.parse(input: filecontents) {
                if remainder != "" {
                    stderrPrint("Parsing left remainder [\(remainder)].\n")
                }
            }
        } catch {
            stderrPrint("Error opening and reading file with filename [\(filename)].\n")
        }
    }
    
} else {
    
    print("The code in main.swift is just a basic exercise of the classes that you have been provided with. It is not an example of well structured and/or thoroughly tested code, so you should probably replace it with an improved version!")

    func testGrammarRule(rule:GrammarRule, input:String) {
        if let remainingInput = rule.parse(input: input){
            print("Was able to parse input=\"\(input)\", with remainingInput=\"\(remainingInput)\"")
        } else {
            print("Was unable to parse input=\"\(input)\"")
        }
    }
    
    func output(rule: GrammarRule, input: String) {
        _ = rule.parse(input: input)
    }
    

    print(" ")
    print("--- Test GRInteger parsing")
    let myGRInteger = GRInteger()
    // should parse the complete string
    testGrammarRule(rule: myGRInteger,input:"2")
    // should parse just the initial integer
    testGrammarRule(rule: myGRInteger,input:"  1200r3f")
    // should not be able to be parsed
    testGrammarRule(rule: myGRInteger,input:"NaN")
    
    print(" ")
    print("--- Test GRLiteral parsing")
    let bGRLiteral = GRLiteral(literal: "b")
    testGrammarRule(rule: bGRLiteral,input:"2")
    testGrammarRule(rule: bGRLiteral,input:" b+a")
    
    print(" ")
    print("--- Test GRExpression parsing")
    let myExpr = GRExpression()
    testGrammarRule(rule: myExpr, input: " 1* 2 ")
    if let result = myExpr.parse(input: " 1 * 2 ") {
        print("myExpr.calculatedValue is \(myExpr.calculatedValue!)")
    }
    testGrammarRule(rule: myExpr, input: "10+10*2+6")
    if let result = myExpr.parse(input: "10+10*2+6") {
        print("myExpr.calculatedValue is \(myExpr.calculatedValue!)")
    }
    testGrammarRule(rule: myExpr, input: " 1 ")
    if let result = myExpr.parse(input: " 1") {
        print("myExpr.calculatedValue is \(myExpr.calculatedValue!)")
    }

    
    print(" ")
    print("--- Test GRSpreadsheet parsing")
    let mySpreadsheet = GRSpreadsheet()
    testGrammarRule(rule: mySpreadsheet, input: " 1+ 3 ")
    testGrammarRule(rule: mySpreadsheet, input: "An epsilon GRSpreadsheet match")
    testGrammarRule(rule: mySpreadsheet, input: "1+2+3")
    
    print(" ")
    print("--- Test GRAssignment parsing")
    let myAssign = GRAssignment()
    testGrammarRule(rule: myAssign, input: "A1 := 1 ")
    testGrammarRule(rule: myAssign, input: "A1 := 1+ 2 ")
    testGrammarRule(rule: myAssign, input: "C5 := 4 + 2")
    testGrammarRule(rule: myAssign, input: "AB1 := 100")
    
    print(" ")
    print("--- Test GRProductTerm parsing")
    let myProduct = GRProductTerm()
    testGrammarRule(rule: myProduct, input: "2*5")
    if let result = myProduct.parse(input: "2*5") {
        // if the parsing was successful, then an GRPRoductTerm should contain a calculatedValue, hence the (not ideal) unsafe optional forcing here.
        print("myProduct.calculatedValue is \(myProduct.calculatedValue ?? 0)")
    }
    testGrammarRule(rule: myProduct, input: "3*6*2")
    if let result = myProduct.parse(input: "3*6*2") {
        // if the parsing was successful, then an GRProductTerm should contain a calculatedValue, hence the (not ideal) unsafe optional forcing here.
        print("myProduct.calculatedValue is \(myProduct.calculatedValue ?? 0)")
    }
    
    print(" ")
    print("----Test GRCellReference (AbsoluteCell) parsing")
    let myACell = GRCellReference()
    testGrammarRule(rule: myACell,input: "C5")
    
    print(" ")
    print("----Test GRCellReference (RelativeCell) parsing")
    let myRCell = GRCellReference()
    testGrammarRule(rule: myRCell,input: "C5 := r5c2 + 10")
    
    print(" ")
    print("----Test GRPrint --")
    let p = GRPrint()
    testGrammarRule(rule: myAssign, input: "C5 := 4 + 2")
    testGrammarRule(rule: myAssign, input: "A5 := A1 + 2")
    testGrammarRule(rule: myAssign, input: "A3 := 10 * 2")
    testGrammarRule(rule: p ,input: "print_value C5")
    testGrammarRule(rule: p ,input: "print_expr A5")
    testGrammarRule(rule: p, input: "print_value A3")
    
    
    print(" ")
    print("----Test GRQuotedString")
    let q = GRQuotedString()
    testGrammarRule(rule: q, input: "\"covfefe\"")
    testGrammarRule(rule: q, input: "my name is oiver")
    testGrammarRule(rule: q, input: "A20 := 63")
    
    /**
    print(" ")
    print("---Test Sample Input from Spec")
    let spread = GRSpreadsheet()
    testGrammarRule(rule: spread, input: "A1 := 1")
    testGrammarRule(rule: spread, input: "A2 := \"covfefe\"")
    testGrammarRule(rule: spread, input: "C5 := 3 + 1")
    testGrammarRule(rule: spread, input: "print_expr A1")
    testGrammarRule(rule: spread, input: "print_value A1")
    testGrammarRule(rule: spread, input: "print_expr A2")
    testGrammarRule(rule: spread, input: "print_value A2")
    testGrammarRule(rule: spread, input: "A2 := 2")
    testGrammarRule(rule: spread, input: "A3 := A1 + A2")
    testGrammarRule(rule: spread, input: "print_expr A3")
    testGrammarRule(rule: spread, input: "print_value A3")
    testGrammarRule(rule: spread, input: "A1 := r1c0 + 1")
    testGrammarRule(rule: spread, input: "print_value A3")
    **/
    
    print(" ")
    print("---Outputs")
    let spread = GRSpreadsheet()
    output(rule: spread, input: "A1 := 1")
    output(rule: spread, input: "A2 := \"covfefe\"")
    output(rule: spread, input: "print_expr A1")
    output(rule: spread, input: "print_value A1")
    output(rule: spread, input: "print_expr A2")
    output(rule: spread, input: "print_value A2")
    output(rule: spread, input: "A2 := 29")
    output(rule: spread, input: "A3 := A1 + A2")
    output(rule: spread, input: "print_expr A3")
    //output(rule: spread, input: "print_value A2")
    //output(rule: spread, input: "print_value A3")
    output(rule: spread, input: "A1 := r1c0 + 1")
    output(rule: spread, input: "print_value A3")
    output(rule: spread, input: "AA105 := 1*2*2*10")
    output(rule: spread, input: "print_expr AA105")
    output(rule: spread, input: "print_value AA105")
    print(" ")
}
