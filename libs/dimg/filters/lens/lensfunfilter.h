/* ============================================================
 *
 * Date        : 2008-02-10
 * Description : a plugin to fix automatically camera lens aberrations
 *
 * Copyright (C) 2008 by Adrian Schroeter <adrian at suse dot de>
 * Copyright (C) 2008-2010 by Gilles Caulier <caulier dot gilles at gmail dot com>
 * Copyright (C) 2010 by Martin Klapetek <martin dot klapetek at gmail dot com>
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

#ifndef LENSFUNFILTER_H
#define LENSFUNFILTER_H

// Local includes

#include "dimgthreadedfilter.h"
#include "digikam_export.h"

namespace Digikam
{

class LensFunIface;
class LensFunFilterPriv;

class DIGIKAM_EXPORT LensFunContainer
{

public:

    LensFunContainer()
    {
        filterCCA  = true;
        filterVig  = true;
        filterCCI  = true;
        filterDist = true;
        filterGeom = true;
    };

    ~LensFunContainer(){};

public:

    bool filterCCA;
    bool filterVig;
    bool filterCCI;
    bool filterDist;
    bool filterGeom;
};

class DIGIKAM_EXPORT LensFunFilter : public DImgThreadedFilter
{

public:

    LensFunFilter(DImg* origImage, QObject* parent, LensFunIface* iface,
                  const LensFunContainer& settings=LensFunContainer());
    ~LensFunFilter();

    static QString          FilterIdentifier() { return "digikam:LensFunFilter"; }
    static QString          DisplayableName() { return "Lenfs Fun Filter"; }
    static QList<int>       SupportedVersions() { return QList<int>() << 1; }
    static int              CurrentVersion() { return 1; }
    
    virtual QString         filterIdentifier() const { return FilterIdentifier(); }
    virtual FilterAction    filterAction();
    void                    readParameters(const FilterAction& action);

private:

    void filterImage();

private:

    LensFunFilterPriv* const d;
};

}  // namespace Digikam

#endif /* LENSFUNFILTER_H */
