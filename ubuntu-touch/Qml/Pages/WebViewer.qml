/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2020  Daniel Kutka

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see [http://www.gnu.org/licenses/].
*/

import QtQuick 2.9
import QtWebEngine 1.7
import QtQuick.Controls 2.2
import QtQuick.Controls.Suru 2.2
import "../"

Page {
    title: webView.title
    property url url

    function getButtons(){
        return toolButtons
    }

    Component {
        id: toolButtons
        Row {
            ActionButton {
                id:del
                ico: "qrc:/Icons/reload.svg"
                size: Suru.units.gu(3)
                color: Suru.color(Suru.White,1)
                onClicked: {
                    webView.reload();
                }
            }

            ActionButton {
                id:edit
                ico: "qrc:/Icons/webbrowser-app-symbolic.svg"
                size: Suru.units.gu(3)
                color: Suru.color(Suru.White,1)
                onClicked: {
                    Qt.openUrlExternally(url);
                }
            }
        }
    }

    WebEngineView{
        anchors.fill: parent
        id:webView
        settings.fullScreenSupportEnabled: true
        zoomFactor: Suru.units.dp(1.0)

        onFullScreenRequested: {
            if(request.toggleOn) {
                window.showFullScreen()
            }
            else
                window.showNormal()
            request.accept()
        }

        onNewViewRequested: {
            Qt.openUrlExternally(request.requestedUrl);
        }
    }

    Component.onCompleted: {
        webView.url = url;
    }
}
