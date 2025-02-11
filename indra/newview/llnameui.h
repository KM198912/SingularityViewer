/**
 * @file llnameui.h
 * @brief display and refresh a name from the name cache
 *
 * $LicenseInfo:firstyear=2003&license=viewergpl$
 *
 * Copyright (c) 2003-2009, Linden Research, Inc. 2019, Liru F�rs
 *
 * Second Life Viewer Source Code
 * The source code in this file ("Source Code") is provided by Linden Lab
 * to you under the terms of the GNU General Public License, version 2.0
 * ("GPL"), unless you have obtained a separate licensing agreement
 * ("Other License"), formally executed by you and Linden Lab.  Terms of
 * the GPL can be found in doc/GPL-license.txt in this distribution, or
 * online at http://secondlifegrid.net/programs/open_source/licensing/gplv2
 *
 * There are special exceptions to the terms and conditions of the GPL as
 * it is applied to this Source Code. View the full text of the exception
 * in the file doc/FLOSS-exception.txt in this software distribution, or
 * online at
 * http://secondlifegrid.net/programs/open_source/licensing/flossexception
 *
 * By copying, modifying or distributing this software, you acknowledge
 * that you have read and understood your obligations described above,
 * and agree to abide by those obligations.
 *
 * ALL LINDEN LAB SOURCE CODE IS PROVIDED "AS IS." LINDEN LAB MAKES NO
 * WARRANTIES, EXPRESS, IMPLIED OR OTHERWISE, REGARDING ITS ACCURACY,
 * COMPLETENESS OR PERFORMANCE.
 * $/LicenseInfo$
 */

#pragma once

#include <set>

#include "lfidbearer.h"

struct LLNameUI : public LFIDBearer
{
	LLNameUI(const std::string& loading = LLStringUtil::null, bool rlv_sensitive = false, const LLUUID& id = LLUUID::null, bool is_group = false);
	virtual ~LLNameUI()
	{
		if (mIsGroup)
			sInstances.erase(this);
		else
			mConnection.disconnect();
	}

	LLUUID getStringUUIDSelectedItem() const override final { return mNameID; }
	uuid_vec_t getSelectedIDs() const override final { return { mNameID }; }
	S32 getNumSelected() const override final { return 1; }

	void setNameID(const LLUUID& name_id, bool is_group);
	void setNameText(); // Sets the name to whatever the name cache has at the moment
	void refresh(const LLUUID& id, const std::string& full_name, bool is_group);
	static void refreshAll(const LLUUID& id, const std::string& full_name, bool is_group);

	void setShowCompleteName(bool show) { mShowCompleteName = show; }
	void showProfile();

	virtual void displayAsLink(bool link) = 0; // Override to make the name display as a link
	virtual void setText(const std::string& text) = 0;

	// Take either UUID or a map of "id" to UUID and "group" to boolean
	virtual void setValue(const LLSD& value)
	{
		if (value.has("id"))
			setNameID(value["id"].asUUID(), value["group"].asBoolean());
		else
			setNameID(value.asUUID(), mIsGroup);
	}
	// Return agent UUIDs
	virtual LLSD getValue() const { return LLSD(mNameID); }

private:
	static std::set<LLNameUI*> sInstances;
	boost::signals2::connection mConnection;
	bool mShowCompleteName = false;

protected:
	LLUUID mNameID;
	bool mRLVSensitive; // Whether or not we're doing RLV filtering
	bool mIsGroup;
	bool mAllowInteract;
	std::string mInitialValue;
};