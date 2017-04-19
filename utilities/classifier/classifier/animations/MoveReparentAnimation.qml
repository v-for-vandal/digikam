import QtQuick 2.0

// MoveReparent animation moves target to given point (0,0) of given parent and reparents it at the end
SequentialAnimation {
    id: movementAnimation
    property Item target;
    property Item newParent
    property point targetPoint // In movement-field-item coordinates
    property int duration

    // Move
    ParallelAnimation {

        NumberAnimation {
            target: movementAnimation.target
            duration: movementAnimation.duration
            properties: "x"
            to: { target.parent.mapFromItem(newParent,0,0).x }
            // to: targetPoint.x
            //to: newParent.mapToItem(target.parent, 0, 0).x
            // from will be automatically deduced from current value
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: movementAnimation.target
            duration: movementAnimation.duration
            properties: "y"
            to: targetPoint.y
            easing.type: Easing.InOutQuad
        }
    }
    // Reparent
    ScriptAction {
        script: {target.parent = newParent; target.x = 0; target.y = 0; } // TODO: REMOVE anchors
    }

    ScriptAction {
        script: {console.log( "Movement animation finished. id: ", movementAnimation);} // TODO: REMOVE
    }

}
