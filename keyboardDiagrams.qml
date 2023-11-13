
//==============================================
//  Add Piano Diagrams above notes v1.0
//
//  Copyright (C)2023 Christian Pearce (pearcec)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//==============================================

import QtQuick 2.2
import MuseScore 3.0

MuseScore {
    version: "1.0"
    description: "Add Piano Diagrams above notes"
    title: "Keyboard Diagrams"
    categoryCode: "composing-arranging-tools"
    thumbnailName: "keyboardDiagrams.png"

    property string fontFace: "Keyboard Chord Diagram"
    property int fontSize: 21

    property string octaveFontFace: cursor.score.styleSettings.value(StyleId.MusicalTextFont);
    property int octaveFontSize: 7

    // Add notation to score
    function addNotation(cursor, notation, fontFace, fontSize) {
        var text = newElement(Element.STAFF_TEXT)

        text.fontFace = fontFace
        text.fontSize = fontSize

        text.text = notation
        if (cursor.voice === 1 || cursor.voice === 3) text.placement = Placement.BELOW;
        console.log("Adding notation: " + notation)
        cursor.add(text)
    }

    // Get formula from notes
    function getFormula(notes) {
        var formula = [];
        for (var i = 0; i < notes.length; i++) {
            if (!notes[i].visible) continue;
            formula.push(notes[i].pitch);
        }
        console.log("Formula: " + formula.join(" "));

        return formula;
    }

    // Get keyboard with dots
    function dotKeyboard(notes, formula) {  
        // Get keyboard
        var keyboard = [
            'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w', 'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w',
            'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w', 'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w',
            'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w', 'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w',
            'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w', 'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w',
            'C|w', 'b', 'w', 'b', 'w', '|w', 'b', 'w', 'b', 'w', 'b', 'w'];
    
        // Mark keys
        formula.forEach(function (selection) {
            selection = parseInt(selection);
            if (keyboard[selection] == "w") keyboard[selection] = "W";
            if (keyboard[selection] == "|w") keyboard[selection] = "|W";
            if (keyboard[selection] == 'C|w') keyboard[selection] = 'C|W';
            if (keyboard[selection] == "b") keyboard[selection] = "B";
        });

        console.log("Keyboard: " + keyboard.join(" "));

        return keyboard;
    }

    // Get keyboard diagram
    function diagramKeyboard(keyboard, formula) {     
        var first = parseInt(formula[0]);
        var last = parseInt(formula[formula.length - 1]);

        // Get start and end of diagram
        var start = keyboard[first] == "B" ? first - 1 : first;
        var end = keyboard[last] == "B" ? last + 1 : last;

        var diagram = keyboard.slice(start, end + 1).join("");

        // Keep slicing until the diagram contains a "C|w" or "C|W"
        while (!diagram.includes("C|w") && !diagram.includes("C|W") && start > 0) {
            start--;
            diagram = "|" + keyboard.slice(start, end + 1).join("") + "|";
        }

        // TODO try to build a diagram that always has one of these patterns
        // var pattern1 = /C\|wbwbw\|wbwbwbw|/i;
        // var pattern2 = /\|wbwbwbwC\|wbwbw|/i;

        // Add "|" to the end if it starts with "C|" and to the front and back if it doesn't start with "C|"
        if (diagram.startsWith("C|")) {
            diagram = diagram + "|";
        } else {
            diagram = "|" + diagram + "|";
        }

        console.log("Diagram: " + diagram);

        return diagram;
    }

    function decorateDiagram(diagram, fontSize) {
        // Calculate the larger font size
        var largerFontSize = fontSize + 5;

        // Replace "C|W" and "C|w" with "<font size="largerFontSize"/>|<font size="fontSize"/>"
        diagram = diagram.replace(/C\|/g, '<font size="' + largerFontSize + '"/>|<font size="' + fontSize + '"/>');

        console.log("Diagram: " + diagram);

        return diagram;
    }

    function getOctave(octaves, formula) {
        var num = formula[0];
        for (var i = 0; i < octaves.length - 1; i++) {
            if (octaves[i] <= num && octaves[i + 1] > num) {
                return i-1;
            }
        }

        // If no such number is found, return -1
        return -1;
    }

    function getOctaves(keyboard) {
        var indexes = [];

        for (var i = 0; i < keyboard.length; i++) {
            if (keyboard[i] === 'C|w' || keyboard[i] === 'C|W') {
                indexes.push(i);
            }
        }

        console.log("Octaves: " + indexes);

        return indexes;
    }

    onRun: {

        console.log("Running Keyboard Diagrams plugin...")
        curScore.startCmd()

        var cursor = curScore.newCursor();
        var startStaff, endStaff, endTick;
        var fullScore = false;
        cursor.rewind(1);
        if (!cursor.segment) { // no selection
            fullScore = true;
            startStaff = 0;
            endStaff = curScore.nstaves - 1;
        } else {
            startStaff = cursor.staffIdx;
            cursor.rewind(2);
            // Handle selection that includes last measure of the score.
            endTick = cursor.tick === 0 ? curScore.lastSegment.tick + 1 : cursor.tick;
            endStaff = cursor.staffIdx;
        }

        console.log("startStaff: " + startStaff)
        console.log("endStaff: " + endStaff)
        console.log("endTick: " + endTick)

        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.rewind(1);
                cursor.voice = voice;
                cursor.staffIdx = staff;

                // There is no selection, move to beginning of score
                if (fullScore) cursor.rewind(0);

                while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                    if (cursor.element && cursor.element.type === Element.CHORD) {
                        var notes = cursor.element.notes;
                        var diagram = [];
                        var keyboard = [];
                        var formula = getFormula(notes);
                        keyboard = dotKeyboard(notes, formula)
                        diagram = diagramKeyboard(keyboard, formula);
                        diagram = decorateDiagram(diagram, fontSize);
                        addNotation(cursor, diagram, fontFace, fontSize);

                        var octaves = getOctaves(keyboard)
                        var octave = getOctave(octaves, formula);

                        addNotation(cursor, "C<sup>" + octave + "</sup>", octaveFontFace, octaveFontSize);
                    }
                    cursor.next();
                }
            }
        }

        curScore.endCmd()
        quit()
    }
}