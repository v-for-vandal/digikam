/* ============================================================
 *
 * This file is a part of digiKam project
 * http://www.digikam.org
 *
 * Date        : 2009-28-04
 * Description : first run assistant dialog
 *
 * Copyright (C) 2009-2017 by Gilles Caulier <caulier dot gilles at gmail dot com>
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

#ifndef STARTSCANPAGE_H
#define STARTSCANPAGE_H

// Local includes

#include "firstrundlgpage.h"

namespace Digikam
{

class StartScanPage : public FirstRunDlgPage
{
public:

    explicit StartScanPage(FirstRunDlg* const dlg);
    ~StartScanPage();
};

}   // namespace Digikam

#endif /* STARTSCANPAGE_H */
