/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2014  Dickson Leong
    Copyright (C) 2015-2020  Sander van Grieken

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

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.quickddit.Core 1.0

AbstractPage {
    id: mainPage
    objectName: "mainPage"
    title: linkModel.title
    busy: linkVoteManager.busy

    property string subreddit
    property string duplicatesOf
    property string section
    property string sectionTimeRange

    property bool _isComplete: false

    function refresh(sr, keepsection) {
        if (sr !== undefined) {
            // getting messy here :(
            // initialize section to undefined unless explicitly kept,
            // so the subreddit's default section is retrieved in the linkmodel
            if (keepsection === undefined || keepsection === false)
                linkModel.section = LinkModel.UndefinedSection
            linkModel.subreddit = "";
            if (sr === "") {
                linkModel.location = LinkModel.FrontPage;
            } else if (String(sr).toLowerCase() === "all") {
                linkModel.location = LinkModel.All;
            } else if (String(sr).toLowerCase() === "popular") {
                linkModel.location = LinkModel.Popular;
            } else {
                linkModel.location = LinkModel.Subreddit;
                linkModel.subreddit = sr;
            }
        }
        linkModel.refresh(false);
    }

    function refreshMR(multireddit) {
        linkModel.location = LinkModel.Multireddit;
        linkModel.multireddit = multireddit
        linkModel.section = LinkModel.UndefinedSection
        linkModel.refresh(false);
    }

    function refreshDuplicates() {
        linkModel.location = LinkModel.Duplicates
        linkModel.section = LinkModel.UndefinedSection
        linkModel.subreddit = duplicatesOf
        linkModel.refresh(false)
    }

    function newLink() {
        var p = {linkManager: linkManager, subreddit: linkModel.subreddit};
        pageStack.push(Qt.resolvedUrl("SendLinkPage.qml"), p);
    }

    function pushSectionDialog(title, section, onAccepted) {
        var p = {title: title, section: section, frontpage: linkModel.location === LinkModel.FrontPage}
        var dialog = pageStack.push(Qt.resolvedUrl("SectionSelectionDialog.qml"), p);
        dialog.accepted.connect(function() {
            onAccepted(dialog.section, dialog.sectionTimeRange);
        })

    }

    property bool __pushedAttached: false

    onStatusChanged: {
        if (mainPage.status === PageStatus.Active && !__pushedAttached) {
            // get subredditspage and push
            pageStack.pushAttached(globalUtils.getNavPage());
            __pushedAttached = true;
        }
        if (mainPage.status === PageStatus.Inactive && __pushedAttached) {
            __pushedAttached = false
        }
    }

    SilicaListView {
        id: linkListView
        anchors.fill: parent
        model: linkModel

        PullDownMenu {
            MenuItem {
                text: qsTr("About %1").arg(linkModel.location == LinkModel.Subreddit ? "/r/" + linkModel.subreddit
                                                                                     : "/m/" + linkModel.multireddit)
                visible: linkModel.location == LinkModel.Subreddit || linkModel.location == LinkModel.Multireddit
                onClicked: {
                    if (linkModel.location == LinkModel.Subreddit) {
                        pageStack.push(Qt.resolvedUrl("AboutSubredditPage.qml"), {subreddit: linkModel.subreddit});
                    } else {
                        pageStack.push(Qt.resolvedUrl("AboutMultiredditPage.qml"), {multireddit: linkModel.multireddit});
                    }
                }
            }
            MenuItem {
                text: qsTr("New Post")
                visible: linkModel.location == LinkModel.Subreddit
                enabled: quickdditManager.isSignedIn
                onClicked: newLink();
            }
            MenuItem {
                text: qsTr("Section")
                onClicked: {
                    pushSectionDialog(qsTr("Section"), linkModel.section,
                        function(section, sectionTimeRange) {
                            linkModel.section = section;
                            linkModel.sectionTimeRange = sectionTimeRange;
                            linkModel.saveSubredditPrefs();
                            linkModel.refresh(false);
                        });
                }
            }
            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchDialog.qml"), {subreddit: linkModel.subreddit});
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: linkModel.refresh(false);
            }
        }

        header: QuickdditPageHeader { title: mainPage.title }

        delegate: LinkDelegate {
            id: linkDelegate

            menu: Component { LinkMenu {} }
            showMenuOnPressAndHold: false
            showSubreddit: linkModel.location != LinkModel.Subreddit

            onClicked: {
                var p = { link: model, linkVoteManager: linkVoteManager, linkSaveManager: linkSaveManager };
                pageStack.push(Qt.resolvedUrl("CommentPage.qml"), p);
            }

            onPressAndHold: {
                var dialog = openMenu({link: model, linkVoteManager: linkVoteManager, linkSaveManager: linkSaveManager, listItem: linkDelegate});
                dialog.deleteLink.connect(function() {
                    linkDelegate.remorseAction(qsTr("Delete link"), function() {
                        linkManager.deleteLink(model.fullname);
                    })
                });
                dialog.hideLink.connect(function() {
                    linkDelegate.remorseAction(qsTr("Hide link"), function() {
                        linkManager.hideLink(model.fullname);
                    })
                });
            }

            AltMarker { }
        }

        footer: LoadingFooter {
            visible: linkModel.busy || (linkListView.count > 0 && linkModel.canLoadMore)
            running: linkModel.busy
            listViewItem: linkListView
        }

        onAtYEndChanged: {
            if (atYEnd && count > 0 && !linkModel.busy && linkModel.canLoadMore)
                linkModel.refresh(true);
        }

        ViewPlaceholder { enabled: linkListView.count == 0 && !linkModel.busy && _isComplete; text: qsTr("Nothing here :(") }

        VerticalScrollDecorator {}
    }

    LinkModel {
        id: linkModel
        manager: quickdditManager
        onError: infoBanner.warning(errorString)
    }

    LinkManager {
        id: linkManager
        manager: quickdditManager
        linkModel: linkModel
        onSuccess: {
            infoBanner.alert(message);
            pageStack.pop();
        }
        onError: infoBanner.warning(errorString);
    }

    VoteManager {
        id: linkVoteManager
        manager: quickdditManager
        onVoteSuccess: linkModel.changeLikes(fullname, likes);
        onError: infoBanner.warning(errorString);
    }

    SaveManager {
        id: linkSaveManager
        manager: quickdditManager
        onSuccess: linkModel.changeSaved(fullname, saved);
        onError: infoBanner.warning(errorString);
    }

    Component.onCompleted: {
        _isComplete = true
        if (section !== undefined) {
            var si = ["best", "hot", "new", "rising", "controversial", "top", "gilded"].indexOf(section);
            if (si !== -1)
                linkModel.section = si;
            if (sectionTimeRange !== undefined && (si === 4 || si === 5)) {
                var ri = ["hour", "day", "week", "month", "year", "all"].indexOf(sectionTimeRange);
                if (ri !== -1)
                    linkModel.sectionTimeRange = ri
            }
        }
        if (duplicatesOf && duplicatesOf !== "") {
            refreshDuplicates()
            return
        }

        refresh(subreddit, true);
    }
}
