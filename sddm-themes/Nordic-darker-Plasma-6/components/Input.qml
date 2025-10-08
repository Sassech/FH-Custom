import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.4

TextField {
    placeholderTextColor: config.color
    color: config.color
    font.pointSize: config.fontSize
    font.family: config.font
    width: parent.width
    background: Rectangle {
        color: "#fff"
        opacity: 0.1
        radius: 8
        width: parent.width
        height: parent.height
    
        anchors.fill: parent
    }
}
