import QtQuick 2.0
import QtQml.StateMachine 1.0 as DSM

Item {
    id: root
    objectName: "Delegate main"
    // User settings
    property alias cursorObject : stripeView.cursorObject
    property alias stripeModel : stripeView.stripeModel

    NumberAnimation {
        id: heightAnimation
        duration: 500
        easing.type: Easing.InOutQuad
    }

    Rectangle {
        id: rootView
        anchors.fill: parent
        border.width: 5
        border.color: "red"

        Rectangle {
            id: topMargin
            anchors.top : parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            enabled: false
            height: 0


            Behavior on height {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }

        }

        PhotoStripeView {
            id: stripeView
            anchors.top : topMargin.bottom
            anchors.bottom: bottomMargin.top
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Rectangle {
            id: bottomMargin
            anchors.bottom : parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            enabled: false
            height: 0

            Behavior on height {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            id: greyOut
            opacity: 0.5
            visible: false
            enabled: false
            color: "black"
        }

        Behavior on height {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }

        SequentialAnimation {
            id: expandAnimation

            // undo current anchors
            ScriptAction {
                script: rootView.anchors.fill = undefined
            }

            // change parent
            ParentAnimation {
                target: rootView
                newParent: photoStripesView.viewAreaItem
            }

            // Pause for debugging

            PauseAnimation {
                duration: 500
            }
            ScriptAction {
                script: console.log( "rootView parent is", rootView.parent.objectName)
            }

            // change dimensions
            ParallelAnimation {
                PropertyAnimation {
                    target: rootView
                    property: "height"
                    to: photoStripesView.viewAreaItem.height
                }
                PropertyAnimation {
                    target: rootView
                    property: "y"
                    to: 0
                }
                PropertyAnimation {
                    target: rootView
                    property: "width"
                    to: photoStripesView.viewAreaItem.width
                }
                PropertyAnimation {
                    target: rootView
                    property: "x"
                    to: 0
                }
            }

            // Restore anchors
            ScriptAction  {
               script: {rootView.anchors.fill = rootView.parent}
            }

            /*
            PropertyAction {
                target: rootView
                property: "anchors.fill"
                value: photoStripesView.viewAreaItem
            }*/
        }

        SequentialAnimation {
            id: collapseAnimation

            // undo current anchors
            // undo current anchors
            ScriptAction {
                script: rootView.anchors.fill = undefined
            }

            ScriptAction {
                script: console.log( "rootView parent is", rootView.parent.objectName)
            }

            // Change coordinates before changing parent
            // Otherwise animation will be obscured by siblings
            // change anchors
            ParallelAnimation {
                PropertyAnimation {
                    target: rootView
                    property: "height"
                    to: root.height
                }
                PropertyAnimation {
                    target: rootView
                    property: "y"
                    // 0 in root cord/system  to photoStripesView coord/system
                    to: root.mapToItem( rootView.parent, 0, 0).y
                }
            }

            // change parent
            ParentAnimation {
                target: rootView
                newParent: root
            }

            PauseAnimation {
                duration: 500
            }

            // Now restore anchors. It will also fix the situation when during first
            // parallel animation for coords user flicked main ViewSection
            ParallelAnimation {
                PropertyAnimation {
                    duration: 100
                    target: rootView
                    property: "height"
                    to: root.height
                }
                PropertyAnimation {
                    duration: 100
                    target: rootView
                    property: "y"
                    to: 0
                }
            }

            // Restore anchors
            ScriptAction  {
               script: {rootView.anchors.fill = rootView.parent}
            }
            /*
            PropertyAction {
                target: rootView
                property: "anchors.fill"
                value: root
            }*/


        }



        /*ParentAnimation {
            id: reparentingAnimation
            target: rootView
            property alias newX : coordsAnimation
            NumberAnimation {
                id: coordsAnimation
                target: rootView
                properties: "x,y,width,height"
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }*/


        states : [
            State {
                name: "expanded"
                PropertyChanges {
                    target: topMargin
                    height : d.expandedMarginHeight
                }
                PropertyChanges {
                    target: bottomMargin
                    height : d.expandedMarginHeight
                }
            },
            State {
                name: "normal"
                PropertyChanges {
                    target: topMargin
                    height : 0
                }
                PropertyChanges {
                    target: bottomMargin
                    height : 0
                }
            }
        ]
        /*
        transitions: [
            Transition {
                // Do not use transition for default state. That prevents weird animation
                // in the initial phase of component creation
                from: "normal,expanded"
                to: "normal,expanded"
               // ParentAnimation {
                    NumberAnimation {
                        properties: "x,y,width,height"
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                //}
                AnchorAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }

            }
        ]*/


    }

    DSM.StateMachine {
        initialState: inactive
        running: true

        DSM.State {
            id: inactive
            onEntered: {
                greyOut.visible = true;
                rootView.state = "normal";
                console.log( "Stripe ", model.index, " entered inactive state" );
            }

            DSM.SignalTransition {
                targetState: active
                signal: signalDispatcher.activated
            }

            DSM.SignalTransition {
                targetState: expanded
                signal: signalDispatcher.expanded
            }
        }

        DSM.State {
            id: active
            initialState: normal

            onEntered: {greyOut.visible = false; }

            DSM.State {
                id: expanded
                onEntered : {
                    console.log( "Stripe ", model.index, " entered expanded state" );

                    // Reparent
                    //rootView.anchors.fill = undefined
                    collapseAnimation.stop()
                    expandAnimation.start();
                    //rootView.state = "expanded"
                    //reparentingAnimation.stop()
                    //reparentingAnimation.newParent = photoStripesView.viewAreaItem
                    //reparentingAnimation.start();
                    //rootView.parent = photoStripesView.viewAreaItem
                    //rootView.x = 0
                    //rootView.y = 0
                    // Show margins
                    //d.showMargins()
                    // expand height
                    //root.height = Qt.binding( function() { return photoStripesView.height } )
                    //rootView.height = Qt.binding( function() { return photoStripesView.height } )
                    // Move self into view
                    //photoStripesView.ensureStripeVisibility(model.index, true)
                }

                onExited : {
                    // Reparent
                    //rootView.anchors.fill = undefined
                    expandAnimation.stop();
                    collapseAnimation.start();
                    //rootView.state = "normal"
                    //reparentingAnimation.stop();
                    //reparentingAnimation.newParent = root
                    //reparentingAnimation.start();
                    //rootView.parent = root
                    // Disable margins
                    //d.hideMargins()
                    // Collapse height
                    //root.height = Qt.binding(function() {return Math.floor( photoStripesView.height/ photoStripesView.stripesVisible); } )
                    //rootView.height = Qt.binding(function() {return Math.floor( photoStripesView.height/ photoStripesView.stripesVisible); } )
                }

                DSM.SignalTransition {
                    targetState: normal
                    signal: signalDispatcher.collapsed
                }
            }

            DSM.State {
                id: normal

                onEntered : {
                    console.log( "Stripe ", model.index, " entered normal state" );
                    rootView.state = "normal"
                    //d.hideMargins()
                }

                DSM.SignalTransition {
                    targetState: expanded
                    signal: signalDispatcher.expanded
                }
            }

            DSM.SignalTransition {
                targetState: inactive
                signal: signalDispatcher.deactivated
            }
        }
    }

    QtObject {
        id: signalDispatcher

        signal activated;
        signal deactivated;
        signal expanded;
        signal collapsed;

    }

    QtObject {
        id: d

        // Margins in expanded mode
        readonly property int expandedMarginHeight : Math.max( 10, Math.floor(rootView.height / 5) )

        function showMargins() {
            /*
            topMarginAnimation.running = false;
            topMarginAnimation.from = topMargin.height;
            topMarginAnimation.to = Math.max( 10, Math.floor(root.height / 5) )
            topMarginAnimation.running = true*/
            topMargin.height = Math.max( 10, Math.floor(root.height / 5) )
            bottomMargin.height = Math.max( 10, Math.floor(root.height / 5) )
        }

        function hideMargins() {
            /*
            topMarginAnimation.running = false;
            topMarginAnimation.from = topMargin.height;
            topMarginAnimation.to = 0
            topMarginAnimation.running = true*/
            topMargin.height = 0
            bottomMargin.height = 0
        }
    }

    function ensurePhotoVisibility( indexInStripe ) {
        stripeView.ensureVisibilityByIndex(indexInStripe);
    }

    function activate() {
        signalDispatcher.activated()
    }
    function deactivate() {
        signalDispatcher.deactivated()
    }
    function expand() {
        console.log( "Expanding")
        signalDispatcher.expanded()
    }
    function collapse() {
        console.log( "Collapsing")
        signalDispatcher.collapsed()
    }


}
