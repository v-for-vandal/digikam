/* ============================================================
 * Author: Gilles Caulier <caulier dot gilles at free.fr>
 * Date  : 2006-01-20
 * Description : main image editor GUI implementation
 *
 * Copyright 2006 by Gilles Caulier
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

// Qt includes.

#include <qlabel.h>
#include <qdockarea.h>
#include <qlayout.h>
#include <qsplitter.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qfile.h>
#include <qpopupmenu.h>
#include <qcursor.h>
#include <qtimer.h>
#include <qfileinfo.h>

// KDE includes.

#include <kprinter.h>
#include <kkeydialog.h>
#include <kdeversion.h>
#include <kaction.h>
#include <kpopupmenu.h>
#include <kedittoolbar.h>
#include <kaboutdata.h>
#include <kcursor.h>
#include <kstdaction.h>
#include <kapplication.h>
#include <kconfig.h>
#include <klocale.h>
#include <kfiledialog.h>
#include <kmenubar.h>
#include <kimageio.h>
#include <kaccel.h>
#include <kmessagebox.h>
#include <kdebug.h>
#include <kglobal.h>
#include <kstandarddirs.h>
#include <kiconloader.h>
#include <kio/netaccess.h>
#include <kio/job.h>
#include <kprotocolinfo.h>
#include <kglobalsettings.h>
#include <ktoolbar.h>
#include <kstatusbar.h>
#include <kprogress.h>

// Local includes.

#include "canvas.h"
#include "dimginterface.h"
#include "imageplugin.h"
#include "imagepluginloader.h"
#include "imageresizedlg.h"
#include "imageprint.h"
#include "slideshow.h"
#include "iofileprogressbar.h"
#include "iccsettingscontainer.h"
#include "iofilesettingscontainer.h"
#include "savingcontextcontainer.h"
#include "editorwindowprivate.h"
#include "editorwindow.h"

void qt_enter_modal( QWidget *widget );
void qt_leave_modal( QWidget *widget );

namespace Digikam
{

EditorWindow::EditorWindow(const char *name)
            : KMainWindow(0, name, WType_TopLevel|WDestructiveClose)
{
    d = new EditorWindowPriv;

    m_contextMenu            = 0;
    m_canvas                 = 0;
    m_slideShow              = 0;
    m_imagePluginLoader      = 0;
    m_undoAction             = 0;
    m_redoAction             = 0;
    m_fullScreenAction       = 0;
    m_saveAction             = 0;
    m_saveAsAction           = 0;
    m_revertAction           = 0;
    m_fileDeleteAction       = 0;
    m_forwardAction          = 0;
    m_backwardAction         = 0;
    m_firstAction            = 0;
    m_lastAction             = 0;
    m_undoAction             = 0;
    m_redoAction             = 0;
    m_slideShowAction        = 0;
    m_fullScreen             = false;
    m_isReadOnly             = false;
    m_rotatedOrFlipped       = false;
    
    // Settings containers instance.

    m_ICCSettings    = new ICCSettingsContainer();
    m_IOFileSettings = new IOFileSettingsContainer();
    m_savingContext  = new SavingContextContainer();
}

EditorWindow::~EditorWindow()
{
    delete m_canvas;
    delete m_ICCSettings;
    delete m_IOFileSettings;
    delete m_savingContext;
    delete m_slideShow;
    delete d;
}

void EditorWindow::setupStandardConnections()
{
    // -- Canvas connections ------------------------------------------------

    connect(m_canvas, SIGNAL(signalShowNextImage()),
            this, SLOT(slotForward()));
            
    connect(m_canvas, SIGNAL(signalShowPrevImage()),
            this, SLOT(slotBackward()));

    connect(m_canvas, SIGNAL(signalRightButtonClicked()),
            this, SLOT(slotContextMenu()));
            
    connect(m_canvas, SIGNAL(signalZoomChanged(float)),
            this, SLOT(slotZoomChanged(float)));
            
    connect(m_canvas, SIGNAL(signalChanged(bool, bool)),
            this, SLOT(slotChanged(bool, bool)));
            
    connect(m_canvas, SIGNAL(signalSelected(bool)),
            this, SLOT(slotSelected(bool)));
    
    connect(m_canvas, SIGNAL(signalLoadingStarted(const QString &)),
            this, SLOT(slotLoadingStarted(const QString &)));

    connect(m_canvas, SIGNAL(signalLoadingFinished(const QString &, bool, bool)),
            this, SLOT(slotLoadingFinished(const QString &, bool, bool)));

    connect(m_canvas, SIGNAL(signalLoadingProgress(const QString &, float)),
            this, SLOT(slotLoadingProgress(const QString &, float)));

    connect(m_canvas, SIGNAL(signalSavingStarted(const QString &)),
            this, SLOT(slotSavingStarted(const QString &)));

    connect(m_canvas, SIGNAL(signalSavingFinished(const QString &, bool)),
            this, SLOT(slotSavingFinished(const QString &, bool)));

    connect(m_canvas, SIGNAL(signalSavingProgress(const QString&, float)),
            this, SLOT(slotSavingProgress(const QString&, float)));

    // -- Slideshow tool connections -----------------------------------------

    connect(m_slideShow, SIGNAL(finished()),
            m_slideShowAction, SLOT(activate()) );

    // -- if rotating/flipping set the rotatedflipped flag to true -----------

    connect(d->rotate90Action, SIGNAL(activated()),
            this, SLOT(slotRotatedOrFlipped()));
            
    connect(d->rotate180Action, SIGNAL(activated()),
            this, SLOT(slotRotatedOrFlipped()));
            
    connect(d->rotate270Action, SIGNAL(activated()),
            this, SLOT(slotRotatedOrFlipped()));
            
    connect(d->flipHorzAction, SIGNAL(activated()),
            this, SLOT(slotRotatedOrFlipped()));
            
    connect(d->flipVertAction, SIGNAL(activated()),
            this, SLOT(slotRotatedOrFlipped()));
}

void EditorWindow::setupStandardActions()
{
    // -- Standard 'File' menu actions ---------------------------------------------

    m_backwardAction = KStdAction::back(this, SLOT(slotBackward()),
                                    actionCollection(), "editorwindow_backward");

    m_forwardAction = KStdAction::forward(this, SLOT(slotForward()),
                                          actionCollection(), "editorwindow_forward");

    m_firstAction = new KAction(i18n("&First"), "start",
                                KStdAccel::shortcut( KStdAccel::Home),
                                this, SLOT(slotFirst()),
                                actionCollection(), "editorwindow_first");

    m_lastAction = new KAction(i18n("&Last"), "finish",
                               KStdAccel::shortcut( KStdAccel::End),
                               this, SLOT(slotLast()),
                               actionCollection(), "editorwindow_last");

    m_saveAction   = KStdAction::save(this, SLOT(slotSave()),
                                      actionCollection(), "editorwindow_save");

    m_saveAsAction = KStdAction::saveAs(this, SLOT(slotSaveAs()),
                                        actionCollection(), "editorwindow_saveas");

    m_revertAction = KStdAction::revert(m_canvas, SLOT(slotRestore()),
                                        actionCollection(), "editorwindow_revert");

    m_saveAction->setEnabled(false);
    m_saveAsAction->setEnabled(false);
    m_revertAction->setEnabled(false);

    d->filePrintAction = new KAction(i18n("Print Image..."), "fileprint",
                                    CTRL+Key_P,
                                    this, SLOT(slotFilePrint()),
                                    actionCollection(), "editorwindow_print");

    m_fileDeleteAction = new KAction(i18n("Delete File"), "editdelete",
                                     SHIFT+Key_Delete,
                                     this, SLOT(slotDeleteCurrentItem()),
                                     actionCollection(), "editorwindow_delete");

    KStdAction::quit(this, SLOT(close()), actionCollection(), "editorwindow_exit");

    // -- Standard 'Edit' menu actions ---------------------------------------------

    d->copyAction = KStdAction::copy(m_canvas, SLOT(slotCopy()),
                                    actionCollection(), "editorwindow_copy");
    
    d->copyAction->setEnabled(false);

    m_undoAction = new KToolBarPopupAction(i18n("Undo"), "undo",
                                           KStdAccel::shortcut(KStdAccel::Undo),
                                           m_canvas, SLOT(slotUndo()),
                                           actionCollection(), "editorwindow_undo");

    connect(m_undoAction->popupMenu(), SIGNAL(aboutToShow()),
            this, SLOT(slotAboutToShowUndoMenu()));
            
    connect(m_undoAction->popupMenu(), SIGNAL(activated(int)),
            m_canvas, SLOT(slotUndo(int)));

    m_undoAction->setEnabled(false);

    m_redoAction = new KToolBarPopupAction(i18n("Redo"), "redo",
                                           KStdAccel::shortcut(KStdAccel::Redo),
                                           m_canvas, SLOT(slotRedo()),
                                           actionCollection(), "editorwindow_redo");

    connect(m_redoAction->popupMenu(), SIGNAL(aboutToShow()),
            this, SLOT(slotAboutToShowRedoMenu()));
            
    connect(m_redoAction->popupMenu(), SIGNAL(activated(int)),
            m_canvas, SLOT(slotRedo(int)));

    m_redoAction->setEnabled(false);

    // -- Standard 'View' menu actions ---------------------------------------------

    d->zoomPlusAction = KStdAction::zoomIn(m_canvas, SLOT(slotIncreaseZoom()),
                                          actionCollection(), "editorwindow_zoomplus");
    d->zoomMinusAction = KStdAction::zoomOut(m_canvas, SLOT(slotDecreaseZoom()),
                                            actionCollection(), "editorwindow_zoomminus");
    d->zoomFitAction = new KToggleAction(i18n("Zoom &AutoFit"), "viewmagfit",
                                        Key_A, this, SLOT(slotToggleAutoZoom()),
                                        actionCollection(), "editorwindow_zoomfit");

#if KDE_IS_VERSION(3,2,0)
    m_fullScreenAction = KStdAction::fullScreen(this, SLOT(slotToggleFullScreen()),
                                                actionCollection(), this, "editorwindow_fullscreen");
#else
    m_fullScreenAction = new KToggleAction(i18n("Fullscreen"), "window_fullscreen",
                                           CTRL+SHIFT+Key_F, this,
                                           SLOT(slotToggleFullScreen()),
                                           actionCollection(), "editorwindow_fullscreen");
#endif

    d->viewHistogramAction = new KSelectAction(i18n("&Histogram"), "histogram", Key_H,
                                              this, SLOT(slotViewHistogram()),
                                              actionCollection(), "editorwindow_histogram");
    d->viewHistogramAction->setEditable(false);

    QStringList selectItems;
    selectItems << i18n("Hide");
    selectItems << i18n("Luminosity");
    selectItems << i18n("Red");
    selectItems << i18n("Green");
    selectItems << i18n("Blue");
    selectItems << i18n("Alpha");
    d->viewHistogramAction->setItems(selectItems);

    m_slideShowAction = new KToggleAction(i18n("Slide Show"), "slideshow", 0,
                                          this, SLOT(slotToggleSlideShow()),
                                          actionCollection(),"editorwindow_slideshow");

    // -- Standard 'Transform' menu actions ---------------------------------------------

    d->resizeAction = new KAction(i18n("&Resize..."), "resize_image", 0,
                                 this, SLOT(slotResize()),
                                 actionCollection(), "editorwindow_resize");

    d->cropAction = new KAction(i18n("Crop"), "crop",
                               CTRL+Key_X,
                               m_canvas, SLOT(slotCrop()),
                               actionCollection(), "editorwindow_crop");
    
    d->cropAction->setEnabled(false);
    d->cropAction->setWhatsThis( i18n("This option can be used to crop the image. "
                                     "Select the image region to enable this action.") );

    // -- Standard 'Flip' menu actions ---------------------------------------------
    
    d->flipAction = new KActionMenu(i18n("Flip"), "flip", actionCollection(), "editorwindow_flip");
    d->flipAction->setDelayed(false);

    d->flipHorzAction = new KAction(i18n("Horizontally"), 0, Key_Asterisk,
                                   m_canvas, SLOT(slotFlipHoriz()),
                                   actionCollection(), "editorwindow_fliphorizontal");

    d->flipVertAction = new KAction(i18n("Vertically"), 0, Key_Slash,
                                   m_canvas, SLOT(slotFlipVert()),
                                   actionCollection(), "editorwindow_flipvertical");
                                   
    d->flipAction->insert(d->flipHorzAction);
    d->flipAction->insert(d->flipVertAction);

    // -- Standard 'Rotate' menu actions ----------------------------------------

    d->rotateAction = new KActionMenu(i18n("&Rotate"), "rotate_cw",
                                     actionCollection(),
                                     "editorwindow_rotate");
    d->rotateAction->setDelayed(false);

    d->rotate90Action  = new KAction(i18n("90 Degrees"),
                                    0, Key_9, m_canvas, SLOT(slotRotate90()),
                                    actionCollection(),
                                    "rotate_90");
    d->rotate180Action = new KAction(i18n("180 Degrees"),
                                    0, Key_8, m_canvas, SLOT(slotRotate180()),
                                    actionCollection(),
                                    "rotate_180");
    d->rotate270Action = new KAction(i18n("270 Degrees"),
                                    0, Key_7, m_canvas, SLOT(slotRotate270()),
                                    actionCollection(),
                                    "rotate_270");
                                    
    d->rotateAction->insert(d->rotate90Action);
    d->rotateAction->insert(d->rotate180Action);
    d->rotateAction->insert(d->rotate270Action);

    // -- Standard 'Configure' menu actions ----------------------------------------

    KStdAction::keyBindings(this, SLOT(slotEditKeys()),           actionCollection());
    KStdAction::configureToolbars(this, SLOT(slotConfToolbars()), actionCollection());
    KStdAction::preferences(this, SLOT(slotSetup()), actionCollection());

    // -- Standard 'Help' menu actions ---------------------------------------------

    d->imagePluginsHelpAction = new KAction(i18n("Image Plugins Handbooks"),
                                           "digikamimageplugins", 0,
                                           this, SLOT(slotImagePluginsHelp()),
                                           actionCollection(), "editorwindow_imagepluginshelp");

    // -- Init SlideShow instance -------------------------------------------------
    
    m_slideShow = new Digikam::SlideShow(m_firstAction, m_forwardAction);
}

void EditorWindow::setupStandardAccelerators()
{
    d->accelerators = new KAccel(this);
    
    d->accelerators->insert("Exit fullscreen", i18n("Exit Fullscreen"),
                    i18n("Exit out of the fullscreen mode"),
                    Key_Escape, this, SLOT(slotEscapePressed()),
                    false, true);

    d->accelerators->insert("Next Image Key_Space", i18n("Next Image"),
                    i18n("Load Next Image"),
                    Key_Space, this, SLOT(slotForward()),
                    false, true);

    d->accelerators->insert("Previous Image Key_Backspace", i18n("Previous Image"),
                    i18n("Load Previous Image"),
                    Key_Backspace, this, SLOT(slotBackward()),
                    false, true);

    d->accelerators->insert("Next Image Key_Next", i18n("Next Image"),
                    i18n("Load Next Image"),
                    Key_Next, this, SLOT(slotForward()),
                    false, true);

    d->accelerators->insert("Previous Image Key_Prior", i18n("Previous Image"),
                    i18n("Load Previous Image"),
                    Key_Prior, this, SLOT(slotBackward()),
                    false, true);

    d->accelerators->insert("Zoom Plus Key_Plus", i18n("Zoom In"),
                    i18n("Zoom into Image"),
                    Key_Plus, m_canvas, SLOT(slotIncreaseZoom()),
                    false, true);
    
    d->accelerators->insert("Zoom Plus Key_Minus", i18n("Zoom Out"),
                    i18n("Zoom out of Image"),
                    Key_Minus, m_canvas, SLOT(slotDecreaseZoom()),
                    false, true);
}
    
void EditorWindow::setupStatusBar()
{
    m_nameLabel = new IOFileProgressBar(statusBar());
    m_nameLabel->setAlignment(Qt::AlignCenter);
    statusBar()->addWidget(m_nameLabel,1);
    m_zoomLabel = new QLabel(statusBar());
    m_zoomLabel->setAlignment(Qt::AlignCenter);
    statusBar()->addWidget(m_zoomLabel,1);
    m_resLabel  = new QLabel(statusBar());
    m_resLabel->setAlignment(Qt::AlignCenter);
    statusBar()->addWidget(m_resLabel,1);
}

void EditorWindow::printImage(KURL url)
{
    uchar* ptr      = DImgInterface::instance()->getImage();
    int w           = DImgInterface::instance()->origWidth();
    int h           = DImgInterface::instance()->origHeight();
    bool hasAlpha   = DImgInterface::instance()->hasAlpha();
    bool sixteenBit = DImgInterface::instance()->sixteenBit();

    if (!ptr || !w || !h)
        return;

    DImg image(w, h, sixteenBit, hasAlpha, ptr);

    KPrinter printer;
    QString appName = KApplication::kApplication()->aboutData()->appName();
    printer.setDocName( url.filename() );
    printer.setCreator( appName );
#if KDE_IS_VERSION(3,2,0)
    printer.setUsePrinterResolution(true);
#endif

    KPrinter::addDialogPage( new ImageEditorPrintDialogPage( this, (appName.append(" page")).ascii() ));

    if ( printer.setup( this, i18n("Print %1").arg(printer.docName().section('/', -1)) ) )
    {
        ImagePrint printOperations(image, printer, url.filename());
        if (!printOperations.printImageWithQt())
        {
            KMessageBox::error(this, i18n("Failed to print file: '%1'")
                               .arg(url.filename()));
        }
    }
}

void EditorWindow::slotImagePluginsHelp()
{
    KApplication::kApplication()->invokeHelp( QString::null, "digikamimageplugins" );
}

void EditorWindow::slotEditKeys()
{
    KKeyDialog dialog(true, this);
    dialog.insert( actionCollection(), i18n( "General" ) );
    ImagePluginLoader* loader = ImagePluginLoader::instance();
    
    for (ImagePlugin* plugin = loader->pluginList().first();
         plugin; plugin = loader->pluginList().next())
    {
        if (plugin)
        {
            dialog.insert( plugin->actionCollection(), plugin->name() );
        }
    }
    
    dialog.configure();
}

void EditorWindow::slotResize()
{
    int width  = m_canvas->imageWidth();
    int height = m_canvas->imageHeight();

    Digikam::ImageResizeDlg dlg(this, &width, &height);
    
    if (dlg.exec() == QDialog::Accepted &&
        (width != m_canvas->imageWidth() ||
         height != m_canvas->imageHeight()))
        m_canvas->resizeImage(width, height);
}

void EditorWindow::slotAboutToShowUndoMenu()
{
    m_undoAction->popupMenu()->clear();
    QStringList titles;
    m_canvas->getUndoHistory(titles);
    
    if(!titles.isEmpty())
    {
        int id = 1;
        QStringList::Iterator iter = titles.begin();        
        for(; iter != titles.end(); ++iter,++id)
        {
            m_undoAction->popupMenu()->insertItem(*iter, id);
        }        
    }
}

void EditorWindow::slotAboutToShowRedoMenu()
{
    m_redoAction->popupMenu()->clear();
    QStringList titles;
    m_canvas->getRedoHistory(titles);
    
    if(!titles.isEmpty())
    {
        int id = 1;
        QStringList::Iterator iter = titles.begin();        
        for(; iter != titles.end(); ++iter,++id)
        {
            m_redoAction->popupMenu()->insertItem(*iter, id);
        }        
    }
}

void EditorWindow::slotConfToolbars()
{
    saveMainWindowSettings(KGlobal::config(), "ImageViewer Settings");
    KEditToolbar dlg(factory(), this);

    connect(&dlg, SIGNAL(newToolbarConfig()),
            this, SLOT(slotNewToolbarConfig()));

    dlg.exec();
}

void EditorWindow::slotNewToolbarConfig()
{
    applyMainWindowSettings(KGlobal::config(), "ImageViewer Settings");
}

void EditorWindow::slotToggleAutoZoom()
{
    bool checked = d->zoomFitAction->isChecked();

    d->zoomPlusAction->setEnabled(!checked);
    d->zoomMinusAction->setEnabled(!checked);

    m_canvas->slotToggleAutoZoom();
}

void EditorWindow::slotZoomChanged(float zoom)
{
    m_zoomLabel->setText(i18n("Zoom: ") +
                         QString::number(zoom*100, 'f', 2) +
                         QString("%"));

    d->zoomPlusAction->setEnabled(!m_canvas->maxZoom() &&
                                 !d->zoomFitAction->isChecked());
    d->zoomMinusAction->setEnabled(!m_canvas->minZoom() &&
                                  !d->zoomFitAction->isChecked());
}

void EditorWindow::slotEscapePressed()
{
    if (m_fullScreen)
        m_fullScreenAction->activate();
    
    if (m_slideShowAction->isChecked())
        m_slideShowAction->activate();
}

void EditorWindow::plugActionAccel(KAction* action)
{
    if (!action)
        return;

    d->accelerators->insert(action->text(),
                    action->text(),
                    action->whatsThis(),
                    action->shortcut(),
                    action,
                    SLOT(activate()));
}

void EditorWindow::unplugActionAccel(KAction* action)
{
    d->accelerators->remove(action->text());
}

void EditorWindow::loadImagePlugins()
{
    QPtrList<Digikam::ImagePlugin> pluginList = m_imagePluginLoader->pluginList();

    for (Digikam::ImagePlugin* plugin = pluginList.first();
         plugin; plugin = pluginList.next())
    {
        if (plugin)
        {
            guiFactory()->addClient(plugin);
            plugin->setParentWidget(this);
            plugin->setEnabledSelectionActions(false);
        }
        else
            kdDebug() << "Invalid plugin to add!" << endl;
    }
}

void EditorWindow::unLoadImagePlugins()
{
    QPtrList<Digikam::ImagePlugin> pluginList = m_imagePluginLoader->pluginList();

    for (Digikam::ImagePlugin* plugin = pluginList.first();
         plugin; plugin = pluginList.next())
    {
        if (plugin) 
        {
            guiFactory()->removeClient(plugin);
            plugin->setParentWidget(0);
            plugin->setEnabledSelectionActions(false);
        }
    }
}

void EditorWindow::readStandardSettings()
{
    KConfig* config = kapp->config();
    config->setGroup("ImageViewer Settings");    

    // Blended Histogram settings.
    QRect histogramRect = config->readRectEntry("Histogram Rectangle");
    if (!histogramRect.isNull())
        m_canvas->setHistogramPosition(histogramRect.topLeft());
    
    int histogramType = config->readNumEntry("HistogramType", 0);
    histogramType = (histogramType < 0 || histogramType > 5) ? 0 : histogramType;
    d->viewHistogramAction->setCurrentItem(histogramType);
    slotViewHistogram(); // update

    // Restore full screen Mode ?

    if (config->readBoolEntry("FullScreen", false))
    {
        m_fullScreenAction->activate();
        m_fullScreen = true;
    }

    // Restore Auto zoom action ?
    bool autoZoom = config->readBoolEntry("AutoZoom", true);

    if (autoZoom)
    {
        d->zoomFitAction->activate();
        d->zoomPlusAction->setEnabled(false);
        d->zoomMinusAction->setEnabled(false);
    }    
}

void EditorWindow::applyStandardSettings()
{
    KConfig* config = kapp->config();
    config->setGroup("ImageViewer Settings");

    // -- Background color --------------------------------------------------------
    
    d->bgColor = QColor(Qt::black);
    m_canvas->setBackgroundColor(config->readColorEntry("BackgroundColor", &d->bgColor));
//    m_canvas->update();

    // -- IO files format settings ------------------------------------------------
    
    // JPEG quality slider settings : 0 - 100 ==> libjpeg settings : 25 - 100.
    m_IOFileSettings->JPEGCompression  = (int)((75.0/99.0)*(float)config->readNumEntry("JPEGCompression", 75)
                                               + 25.0 - (75.0/99.0));

    // PNG compression slider settings : 1 - 9 ==> libpng settings : 100 - 1.
    m_IOFileSettings->PNGCompression   = (int)(((1.0-100.0)/8.0)*(float)config->readNumEntry("PNGCompression", 1)
                                               + 100.0 - ((1.0-100.0)/8.0));

    m_IOFileSettings->TIFFCompression  = config->readBoolEntry("TIFFCompression", false);

    m_IOFileSettings->rawDecodingSettings.automaticColorBalance = config->readBoolEntry("AutomaticColorBalance", true);
    m_IOFileSettings->rawDecodingSettings.cameraColorBalance    = config->readBoolEntry("CameraColorBalance", true);
    m_IOFileSettings->rawDecodingSettings.RGBInterpolate4Colors = config->readBoolEntry("RGBInterpolate4Colors", false);
    m_IOFileSettings->rawDecodingSettings.enableRAWQuality      = config->readBoolEntry("EnableRAWQuality", false);
    m_IOFileSettings->rawDecodingSettings.RAWQuality            = config->readNumEntry("RAWQuality", 0);

    QSizePolicy rightSzPolicy(QSizePolicy::Preferred, QSizePolicy::Expanding, 2, 1);
    if(config->hasKey("Splitter Sizes"))
        m_splitter->setSizes(config->readIntListEntry("Splitter Sizes"));
    else 
        m_canvas->setSizePolicy(rightSzPolicy);
    
    d->fullScreenHideToolBar = config->readBoolEntry("FullScreen Hide ToolBar", false);

    // -- Slideshow Settings -------------------------------------------------
    
    d->slideShowInFullScreen = config->readBoolEntry("SlideShowFullScreen", true);
    m_slideShow->setStartWithCurrent(config->readBoolEntry("SlideShowStartCurrent", false));
    m_slideShow->setLoop(config->readBoolEntry("SlideShowLoop", false));
    m_slideShow->setDelay(config->readNumEntry("SlideShowDelay", 5));

    // -- Settings for Color Management stuff --------------------------------

    config->setGroup("Color Management");

    m_ICCSettings->enableCMSetting = config->readBoolEntry("EnableCM");
    m_ICCSettings->askOrApplySetting = config->readBoolEntry("BehaviourICC");
    m_ICCSettings->BPCSetting = config->readBoolEntry("BPCAlgorithm");
    m_ICCSettings->renderingSetting = config->readNumEntry("RenderingIntent");
    m_ICCSettings->inputSetting = config->readPathEntry("InProfileFile");
    m_ICCSettings->workspaceSetting = config->readPathEntry("WorkProfileFile");
    m_ICCSettings->monitorSetting = config->readPathEntry("MonitorProfileFile");
    m_ICCSettings->proofSetting = config->readPathEntry("ProofProfileFile");
}

void EditorWindow::saveStandardSettings()
{
    KConfig* config = kapp->config();
    config->setGroup("ImageViewer Settings");
    
    config->writeEntry("AutoZoom", d->zoomFitAction->isChecked());
    config->writeEntry("Splitter Sizes", m_splitter->sizes());

    int histogramType = d->viewHistogramAction->currentItem();
    histogramType = (histogramType < 0 || histogramType > 5) ? 0 : histogramType;
    config->writeEntry("HistogramType", histogramType);

    QPoint pt;
    QRect rc(0, 0, 0, 0);
    if (m_canvas->getHistogramPosition(pt)) 
        rc = QRect(pt.x(), pt.y(), 1, 1);
    config->writeEntry("Histogram Rectangle", rc);

    config->writeEntry("FullScreen", m_slideShowAction->isChecked());
    
    config->sync();
}

void EditorWindow::slotViewHistogram()
{
    int curItem = d->viewHistogramAction->currentItem();
    m_canvas->setHistogramType(curItem);
}

void EditorWindow::toggleStandardActions(bool val)
{
    d->zoomFitAction->setEnabled(val);
    m_saveAsAction->setEnabled(val);
    d->viewHistogramAction->setEnabled(val);
    d->rotateAction->setEnabled(val);
    d->flipAction->setEnabled(val);
    d->filePrintAction->setEnabled(val);
    d->resizeAction->setEnabled(val);
    m_fileDeleteAction->setEnabled(val);

    QPtrList<Digikam::ImagePlugin> pluginList = m_imagePluginLoader->pluginList();
    
    for (Digikam::ImagePlugin* plugin = pluginList.first();
         plugin; plugin = pluginList.next())
    {
        if (plugin) 
        {
            plugin->setEnabledActions(val);
        }
    }
}

void EditorWindow::slotToggleFullScreen()
{
    if (m_fullScreen)
    {
        m_canvas->setBackgroundColor(d->bgColor);

#if QT_VERSION >= 0x030300
        setWindowState( windowState() & ~WindowFullScreen );
#else
        showNormal();
#endif
        menuBar()->show();
        statusBar()->show();
        leftDock()->show();
        rightDock()->show();
        topDock()->show();
        bottomDock()->show();
        
        QObject* obj = child("ToolBar","KToolBar");
        
        if (obj)
        {
            KToolBar* toolBar = static_cast<KToolBar*>(obj);
            
            if (m_fullScreenAction->isPlugged(toolBar) && d->removeFullScreenButton)
                m_fullScreenAction->unplug(toolBar);
                
            if (toolBar->isHidden())
                showToolBars();
        }

        // -- remove the gui action accels ----

        unplugActionAccel(m_forwardAction);
        unplugActionAccel(m_backwardAction);
        unplugActionAccel(m_firstAction);
        unplugActionAccel(m_lastAction);
        unplugActionAccel(m_saveAction);
        unplugActionAccel(m_saveAsAction);
        unplugActionAccel(d->zoomPlusAction);
        unplugActionAccel(d->zoomMinusAction);
        unplugActionAccel(d->zoomFitAction);
        unplugActionAccel(d->cropAction);
        unplugActionAccel(d->filePrintAction);
        unplugActionAccel(m_fileDeleteAction);

        toggleGUI2FullScreen();
        m_fullScreen = false;
    }
    else
    {
        m_canvas->setBackgroundColor(QColor(Qt::black));
        
        // hide the menubar and the statusbar
        menuBar()->hide();
        statusBar()->hide();
        topDock()->hide();
        leftDock()->hide();
        rightDock()->hide();
        bottomDock()->hide();
        
        QObject* obj = child("ToolBar","KToolBar");
        
        if (obj)
        {
            KToolBar* toolBar = static_cast<KToolBar*>(obj);
            
            if (d->fullScreenHideToolBar)
            {
                hideToolBars();
            }
            else
            {    
                if ( !m_fullScreenAction->isPlugged(toolBar) )
                {
                    m_fullScreenAction->plug(toolBar);
                    d->removeFullScreenButton=true;
                }
                else    
                {
                    // If FullScreen button is enable in toolbar settings
                    // We don't remove it when we out of fullscreen mode.
                    d->removeFullScreenButton=false;
                }
            }
        }

        // -- Insert all the gui actions into the accel --

        plugActionAccel(m_forwardAction);
        plugActionAccel(m_backwardAction);
        plugActionAccel(m_firstAction);
        plugActionAccel(m_lastAction);
        plugActionAccel(m_saveAction);
        plugActionAccel(m_saveAsAction);
        plugActionAccel(d->zoomPlusAction);
        plugActionAccel(d->zoomMinusAction);
        plugActionAccel(d->zoomFitAction);
        plugActionAccel(d->cropAction);
        plugActionAccel(d->filePrintAction);
        plugActionAccel(m_fileDeleteAction);

        toggleGUI2FullScreen();
        showFullScreen();
        m_fullScreen = true;
    }
}

void EditorWindow::slotContextMenu()
{
    m_contextMenu->exec(QCursor::pos());
}

void EditorWindow::slotToggleSlideShow()
{
    if (m_slideShowAction->isChecked())
    {
        toggleGUI2SlideShow();
        
        if (!m_fullScreenAction->isChecked() && d->slideShowInFullScreen)
        {
            m_fullScreenAction->activate();
        }

        toggleActions2SlideShow(false);
        m_slideShow->start();
    }
    else
    {
        m_slideShow->stop();
        toggleActions2SlideShow(true);

        if (m_fullScreenAction->isChecked() && d->slideShowInFullScreen)
        {
            m_fullScreenAction->activate();
        }
        
        toggleGUI2SlideShow();
    }
}

void EditorWindow::slotRotatedOrFlipped()
{
    m_rotatedOrFlipped = true;
}

void EditorWindow::slotLoadingProgress(const QString&, float progress)
{
    m_nameLabel->setProgressValue((int)(progress*100.0));
}

void EditorWindow::slotSavingProgress(const QString&, float progress)
{
    m_nameLabel->setProgressValue((int)(progress*100.0));
}

bool EditorWindow::promptUserSave(const KURL& url)
{
    if (m_saveAction->isEnabled())
    {
        int result = KMessageBox::warningYesNoCancel(this,
                                  i18n("The image '%1\' has been modified.\n"
                                       "Do you want to save it?")
                                       .arg(url.filename()),
                                  QString::null,
                                  KStdGuiItem::save(),
                                  KStdGuiItem::discard());

        if (result == KMessageBox::Yes)
        {
            bool saving;

            if (m_isReadOnly)
                saving = saveAs();
            else
                saving = save();

            // save and saveAs return false if they were cancelled and did not enter saving at all
            // In this case, do not call enter_loop because exit_loop will not be called.
            if (saving)
            {
                // Waiting asynchronous image file saving operation runing in separate thread.
                m_savingContext->synchronizingState = SavingContextContainer::SynchronousSaving;
                enter_loop();
                m_savingContext->synchronizingState = SavingContextContainer::NormalSaving;
                return m_savingContext->synchronousSavingResult;
            }
            else
            {
                return false;
            }
        }
        else if (result == KMessageBox::No)
        {
            m_saveAction->setEnabled(false);
            return true;
        }
        else
        {
            return false;
        }
    }

    return true;
}

void EditorWindow::enter_loop()
{
    QWidget dummy(0, 0, WType_Dialog | WShowModal);
    dummy.setFocusPolicy( QWidget::NoFocus );
    qt_enter_modal(&dummy);
    qApp->enter_loop();
    qt_leave_modal(&dummy);
}

void EditorWindow::slotSelected(bool val)
{
    // Update menu actions.
    d->cropAction->setEnabled(val);
    d->copyAction->setEnabled(val);

    for (ImagePlugin* plugin = m_imagePluginLoader->pluginList().first();
         plugin; plugin = m_imagePluginLoader->pluginList().next())
    {
        if (plugin) 
        {
            plugin->setEnabledSelectionActions(val);
        }
    }
    
    // Update histogram into sidebar.
    
    QRect sel = m_canvas->getSelectedArea();
    emit signalSelectionChanged( sel.isNull() ? 0 : &sel );
}

void EditorWindow::hideToolBars()
{
    QPtrListIterator<KToolBar> it = toolBarIterator();
    KToolBar* bar;

    for(;it.current()!=0L; ++it)
    {
        bar=it.current();
        
        if (bar->area()) 
            bar->area()->hide();
        else 
            bar->hide();
    }
}

void EditorWindow::showToolBars()
{
    QPtrListIterator<KToolBar> it = toolBarIterator();
    KToolBar* bar;

    for( ; it.current()!=0L ; ++it)
    {
        bar=it.current();
        
        if (bar->area())
            bar->area()->show();
        else
            bar->show();
    }
}

}  // namespace Digikam

#include "editorwindow.moc"
