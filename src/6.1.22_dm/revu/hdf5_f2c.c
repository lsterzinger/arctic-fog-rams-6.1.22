/*
!
! Copyright (C) 1991-2004  ; All Rights Reserved ; Colorado State University
! Colorado State University Research Foundation ; ATMET, LLC
!
! This file is free software; you can redistribute it and/or modify it under the
! terms of the GNU General Public License as published by the Free Software
! Foundation; either version 2 of the License, or (at your option) any later version.
!
! This software is distributed in the hope that it will be useful, but WITHOUT ANY
! WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
! PARTICULAR PURPOSE.  See the GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along with this
! code; if not, write to the Free Software Foundation, Inc.,
! 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
!======================================================================================
*/

#include "utils_sub_names_nondm.h"

#include "hdf5.h"

hid_t fileid, dsetid, dspcid, mspcid, propid;

/*************************** File routines ***********************************/

/*****************************************************************************/
 void fh5f_open (char*locfn,int*iaccess,int*hdferr)
{

unsigned flags;
hid_t access_id;
extern hid_t fileid;

access_id = H5P_DEFAULT;
if(*iaccess == 1) flags = H5F_ACC_RDONLY;
if(*iaccess == 2) flags = H5F_ACC_RDWR;

fileid = H5Fopen (locfn,flags,access_id);

/*printf("fh5f_open_ - fileid: %d\n",fileid);*/

*hdferr = fileid;

return;
}

/*****************************************************************************/
 void fh5f_create (char*locfn,int*iaccess,int*hdferr)
{

unsigned flags;
hid_t access_id,create_id;
extern hid_t fileid;

access_id = H5P_DEFAULT;
create_id = H5P_DEFAULT;
if(*iaccess == 1) flags = H5F_ACC_TRUNC;
if(*iaccess == 2) flags = H5F_ACC_EXCL ;

fileid = H5Fcreate (locfn,flags,create_id,access_id);

/*printf("fh5f_open_ - fileid: %d\n",fileid);*/

*hdferr = fileid;

return;
}

/*****************************************************************************/
 void fh5f_close (int*hdferr)
{

extern hid_t fileid;
herr_t herr;

herr = H5Fclose (fileid);
/*printf("fh5f_close: %d\n",herr);*/

/*
The following causes problems with REVU since this command forces everything 
to close and flushes all data to disk. This is bad if you have multiple 
processes with hdf5 open. I do not think we need to use this H5close() cmd.
*/
/*herr = H5close ();*/
/*printf("H5_close: %d\n",herr);*/

*hdferr = herr;

return;
}

/******************************* Dataset routines ****************************/

/*****************************************************************************/
 void fh5d_open (char*dname,int*hdferr)
{

extern hid_t fileid;
herr_t herr;

/* HDF5 1.8 API */
dsetid = H5Dopen (fileid,dname,H5P_DEFAULT);

/*printf("fh5d_open: %d\n",dsetid);*/

if (dsetid < 0) { *hdferr = dsetid; return;}

dspcid = H5Dget_space (dsetid);
/*printf("fh5d_get_space: %d\n",dspcid);*/

*hdferr = dspcid;

return;
}

/*****************************************************************************/
 void fh5d_close (int*hdferr)
{

extern hid_t dsetid;
herr_t herr;

herr = H5Dclose (dsetid);
/*printf("fh5d_close: %d\n",herr);*/

*hdferr = herr;

return;
}

/************************ Dataset info routines ******************************/

/*****************************************************************************/
 void fh5s_get_ndims (int*ndims)
{

extern hid_t dspcid;
int result;

result = H5Sget_simple_extent_ndims (dspcid);
/* printf("fh5d_get_ndims: %d\n",result); */

*ndims = result;

return;
}

/*****************************************************************************/
 void fh5s_get_dims (int*dims)
{

extern hid_t dspcid;
hsize_t dimsc[7], maxdimsc[7];
int ndims,i;

ndims = H5Sget_simple_extent_dims (dspcid,dimsc,maxdimsc);
/*printf("fh5d_get_dims: %d %d %d %d\n",ndims,dimsc[0],dimsc[1],dimsc[2]);*/
 
for (i = 0; i < ndims; i++) {  dims[i] = dimsc[i];   }
/*printf("fh5d_get_dims: %d %d %d %d\n",ndims,dimsc[0],dimsc[1],dimsc[2]);*/
return;
}

/****************************** Reading routines *****************************/

/*****************************************************************************/
 void fh5_prepare_read (char*dname,int*hdferr)
{

extern hid_t fileid, dsetid, dspcid, mspcid;

int i;
herr_t herr;

*hdferr = 0;

/* HDF5 1.8 API */
dsetid = H5Dopen (fileid,dname,H5P_DEFAULT);

/*printf("fh5_prep - open: %d\n",dsetid);*/
if (dsetid < 0) { *hdferr = dsetid; return;}

return;
}

/*****************************************************************************/
 void fh5d_read (int*h5type,void*buf,int*hdferr)
{

extern hid_t dsetid, dspcid, mspcid;
herr_t herr;
hid_t memtype;

if (*h5type == 1) memtype=H5T_NATIVE_INT;
if (*h5type == 2) memtype=H5T_NATIVE_FLOAT;
if (*h5type == 3) memtype=H5T_NATIVE_CHAR;
if (*h5type == 4) memtype=H5T_NATIVE_DOUBLE;
if (*h5type == 5) memtype=H5T_NATIVE_HBOOL;

herr = H5Dread (dsetid,memtype,H5S_ALL,H5S_ALL,H5P_DEFAULT,buf);
/*printf("fh5d_read: %d\n",herr);*/
/*exit(0);*/

*hdferr = herr;

return;
}

/*****************************************************************************/
 void fh5_close_read (int*hdferr)
{

extern hid_t dsetid, dspcid, mspcid;
herr_t herr;

herr = H5Dclose (dsetid);
/*printf("fh5d_close: %d\n",herr);*/

*hdferr = herr;

return;
}

/**************************** Writing routines *******************************/

/*****************************************************************************/
 void fh5_prepare_write (int*ndims,int*dims,int*hdferr)
{

extern hid_t fileid, dsetid, dspcid, mspcid, propid;
int i;
herr_t herr;

hsize_t dimsc[7]  = {1,1,1,1,1,1,1};
hsize_t maxdims[7]  = {1,1,1,1,1,1,1};
hsize_t chunk_size[7]  = {0,0,0,0,0,0,0};

for (i = 0; i < *ndims; i++) {  dimsc[i] = dims[i]; chunk_size[i] = dims[i];  
                                maxdims[i] = dims[i];}

/*  Create the data space for the dataset. */
mspcid = H5Screate_simple (*ndims,dimsc,maxdims);
/*printf("fh5_prepw - create 1: %d\n",mspcid);*/

/* Create properties for gzip compression.*/
propid = H5Pcreate (H5P_DATASET_CREATE);
/*printf("fh5_prepw - propid: %d\n",propid);*/

herr = H5Pset_chunk (propid,*ndims,chunk_size);
herr = H5Pset_shuffle (propid);
herr = H5Pset_deflate (propid,6);

*hdferr = herr;
/*printf("fh5_prepw - compress: %d\n",mspcid);*/

return;
}

/*****************************************************************************/
 void fh5_write (int*h5type,void*buf,char*dname,int*hdferr)
{

extern hid_t fileid, dsetid, dspcid, mspcid, propid;
herr_t herr;
hid_t memtype;

if (*h5type == 1) memtype=H5T_NATIVE_INT32;
if (*h5type == 2) memtype=H5T_NATIVE_FLOAT;
if (*h5type == 3) memtype=H5T_STRING;
if (*h5type == 4) memtype=H5T_NATIVE_DOUBLE;
if (*h5type == 5) memtype=H5T_NATIVE_HBOOL;
/*printf("fh5_write - start: %d \n",memtype);*/

/* HDF5 1.8 API */
dsetid = H5Dcreate (fileid,dname,memtype,mspcid,H5P_DEFAULT,propid,H5P_DEFAULT);
/*printf("fh5_write - create 1: %d\n",dsetid);*/

herr = H5Dwrite (dsetid,memtype,H5S_ALL,H5S_ALL,H5P_DEFAULT,buf);
/*printf("fh5_write - write 1: %d\n",herr);*/

*hdferr = herr;

return;
}

/*****************************************************************************/
 void fh5_close_write (int*hdferr)
{

extern hid_t dsetid, dspcid, mspcid;
herr_t herr;

herr = H5Sclose (mspcid);
herr = H5Pclose (propid);
herr = H5Dclose (dsetid);
/*printf("fh5_close_write: %d\n",herr);*/

*hdferr = herr;

return;
}
