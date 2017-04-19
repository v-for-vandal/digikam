import QtQuick 2.0

// MoveReparent animation moves target to given point (0,0) of given parent and reparents it at the end
SequentialAnimation {
    id: movementAnimation
    property Item target;
    property Item newParent
    property point targetPoint // In movement-field-item coordinates TODO: REMOVE
    property int duration
    property var stripeObject : null // Must have methods raiseStripeZ/restoreStripeZ

    // Raise stripe Z
    ScriptAction {
        script: stripeObject.raiseStripeZ();
    }

    // Reparent
    /*
    ScriptAction {
        script: {
            var coords = target.mapToItem(newParent, 0 ,0)
            target.parent = newParent;

            target.x = coords.x; target.y = coords.y;
            console.log("Repartende coords: ", coords)
        }
        // TODO: REMOVE anchors
    }*/

    // Move
    ParallelAnimation {

        NumberAnimation {
            target: movementAnimation.target
            duration: movementAnimation.duration
            properties: "x"
            //to: { target.parent.mapFromItem(newParent,0,0).x }
            to: 0
            // to: targetPoint.x
            //to: newParent.mapToItem(target.parent, 0, 0).x
            // from will be automatically deduced from current value
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: movementAnimation.target
            duration: movementAnimation.duration
            properties: "y"
            //to: targetPoint.y
            to: 0
            easing.type: Easing.InOutQuad
        }
    }

    ScriptAction {
        script: stripeObject.restoreStripeZ();
    }

    ScriptAction {
        script: {console.log( "Movement animation finished. id: ", movementAnimation);} // TODO: REMOVE
    }

}
