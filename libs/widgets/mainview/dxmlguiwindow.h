/* ============================================================
 *
 * This file is a part of digiKam project
 * http://www.digikam.org
 *
 * Date        : 2013-04-29
 * Description : digiKam XML GUI window
 *
 * Copyright (C) 2013-2015 by Gilles Caulier <caulier dot gilles at gmail dot com>
 *
 * This program is free software; you can redistribute it
 * and/or modify it under the terms of the GNU General
 * Public License as published by the Free Software Foundation;
 * either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * ============================================================ */

#ifndef DXMLGUIWINDOW_H
#define DXMLGUIWINDOW_H

// Qt includes

#include <QWidget>
#include <QObject>
#include <QAction>
#include <QWindow>

// KDE includes

#include <kxmlguiwindow.h>
#include <kconfiggroup.h>

// Local includes

#include "digikam_export.h"
#include "dlogoaction.h"

class QEvent;

class KToolBar;

namespace Digikam
{

/** Optional parts which can be hidden or not from managed window configuration panel
 */
enum FullScreenOptions
{
    FS_TOOLBARS   = 0x00000001,                                 /// Manage Tools bar in full-screen mode.
    FS_THUMBBAR   = 0x00000002,                                 /// Manage Thumb bar in full-screen mode.
    FS_SIDEBARS   = 0x00000004,                                 /// Manage Side bars in full-screen mode.
    FS_NONE       = 0x00000008,                                 /// No full-screen options.

    FS_ALBUMGUI   = FS_TOOLBARS | FS_THUMBBAR | FS_SIDEBARS,    /// Album GUI Config.
    FS_EDITOR     = FS_TOOLBARS | FS_THUMBBAR | FS_SIDEBARS,    /// Image Editor Config.
    FS_LIGHTTABLE = FS_TOOLBARS | FS_SIDEBARS,                  /// Light Table Config.
    FS_IMPORTUI   = FS_TOOLBARS | FS_THUMBBAR | FS_SIDEBARS     /// Import UI Config.
};

static const QString s_configFullScreenHideToolBarsEntry("FullScreen Hide ToolBars");
static const QString s_configFullScreenHideThumbBarEntry("FullScreen Hide ThumbBar");
static const QString s_configFullScreenHideSideBarsEntry("FullScreen Hide SideBars");

/** Data container to use in managed window.
 */
class DIGIKAM_EXPORT DXmlGuiWindow : public KXmlGuiWindow
{
    Q_OBJECT

public:

    explicit DXmlGuiWindow(QWidget* const parent=0, Qt::WindowFlags f=KDE_DEFAULT_WINDOWFLAGS);
    virtual ~DXmlGuiWindow();

    /** Create common actions to setup all digiKam main windows.
     */
    void createSettingsActions();

    /** Create common actions from Help menu for all digiKam main windows.
     */
    void createHelpActions(bool coreOptions=true);

    /** Create common actions to handle side-bar through keyboard shortcuts.
     */
    void createSidebarActions();

    /** Set full-screen options to managed window
     */
    void setFullScreenOptions(int options);

    /** Create Full-screen action to action collection instance from managed window
     *  set through setManagedWindow(). This action is connected to slotToggleFullScreen() slot.
     *  'name' is action name used in KDE UI rc file.
     */
    void createFullScreenAction(const QString& name);

    /** Read full-screen settings fr    void slotConfNotifications();om KDE config file.
     */
    void readFullScreenSettings(const KConfigGroup& group);

    /** Return true if managed window is currently in Full Screen Mode.
     */
    bool fullScreenIsActive() const;
    
    static void openHandbook(const QString& anchor = QString(), const QString& appname = QString());
    static void restoreWindowSize(QWindow* const win, const KConfigGroup& group);
    static void saveWindowSize(QWindow* const win, KConfigGroup& group);

protected:

    DLogoAction* m_animLogo;

protected:

    QAction* statusBarMenuAction() const;
    QAction* showMenuBarAction()   const;

    /** Call this method from your main window to show keyboard shortcut config dialog 
     *  with an extra action collection to configure. This method is called by slotEditKeys()
     *  which can be re-implement in child class for cutomization.
     */
    void editKeyboardShortcuts(KActionCollection* const extraac=0, const QString& actitle=QString());

    void closeEvent(QCloseEvent* e);
    void keyPressEvent(QKeyEvent* e);
    bool eventFilter(QObject* obj, QEvent* ev);

    /** Re-implement this method if you want to manage sidebars visibility in full-screen mode.
     *  By default this method do nothing.
     */
    virtual void showSideBars(bool visible);

    /** Re-implement this method if you want to manage thumbbar visibility in full-screen mode.
     *  By default this method do nothing.
     */
    virtual void showThumbBar(bool visible);

    /** Re-implement this method if you want to manage customized view visibility in full-screen mode.
     *  This method is called by switchWindowToFullScreen(). By default this method do nothing.
     */
    virtual void customizedFullScreenMode(bool set);

    /** Re-implement this method if managed window has a thumbbar. This must return visibility state of it.
     */
    virtual bool thumbbarVisibility() const;

private Q_SLOTS:

    void slotToggleFullScreen(bool);
    void slotShowMenuBar();
    void slotConfNotifications();

    // Slots for common Help Actions
    virtual void slotComponentsInfo()          {};
    virtual void slotDBStat()                  {};

    // Slots for common Sidebar Actions
    virtual void slotToggleLeftSideBar()       {};
    virtual void slotToggleRightSideBar()      {};
    virtual void slotPreviousLeftSideBarTab()  {};
    virtual void slotNextLeftSideBarTab()      {};
    virtual void slotPreviousRightSideBarTab() {};
    virtual void slotNextRightSideBarTab()     {};

    // Slots for common Settings actions
    virtual void slotEditKeys()                { editKeyboardShortcuts(); };
    virtual void slotSetup() = 0;

private:

    /** Used by slotToggleFullScreen() to switch tool-bar visibility in managed window
     */
    void showToolBars(bool visible);

    /** Return main tool bar instance created in managed window.
     */
    KToolBar* mainToolBar() const;

private:

    class Private;
    Private* const d;
};

} // namespace Digikam

#endif /* DXMLGUIWINDOW_H */
