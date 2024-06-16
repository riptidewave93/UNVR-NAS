/*
 * Copyright (C) 2024 Chris Blake <chrisrblake93@gmail.com>
 *
 * Inspired by mtd-rw: https://github.com/jclehner/mtd-rw/tree/master
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */
 
#include <linux/init.h>
#include <linux/module.h>
#include <linux/mtd/mtd.h>
#include <linux/err.h>

#ifndef MODULE
#error "uvnt-mtd-lock must be compiled as a module."
#endif

#define MOD_INFO KERN_INFO "ubnt-mtd-lock: "
#define MOD_ERR KERN_ERR "ubnt-mtd-lock: "

static int set_readonly(unsigned n)
{
	struct mtd_info *mtd = get_mtd_device(NULL, n);
	int err;

	if (IS_ERR(mtd)) {
		if (PTR_ERR(mtd) != -ENODEV) {
			printk(MOD_ERR "error probing mtd%d %ld\n", n, PTR_ERR(mtd));
		}
		return PTR_ERR(mtd);
	}

	err = -EEXIST;

	if (mtd->flags & MTD_WRITEABLE) {
		printk(MOD_INFO "setting mtd%d \"%s\" readonly\n", n, mtd->name);
		mtd->flags &= ~MTD_WRITEABLE;
		err = 0;
	}

	put_mtd_device(mtd);
	return err;
}

int ubnt_mtd_lock_init(void)
{
	int i, err;

    /* For all MTD partitions, go RO. Assume <10 for UNVR/UNVRPRO */
	for (i = 0; i < 10; ++i) {
		err = set_readonly(i);
		if (err == -ENODEV) {
			break;
		}
	}

	return 0;
}

void ubnt_mtd_lock_exit(void)
{
     /* Do nothing, we wanna keep mtd locked!!! */
}

module_init(ubnt_mtd_lock_init);
module_exit(ubnt_mtd_lock_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Chris Blake <chrisrblake93@gmail.com>");
MODULE_DESCRIPTION("Unifi UNVR/UNVRPRO driver to force MTD partitions RO");
MODULE_VERSION("1");
