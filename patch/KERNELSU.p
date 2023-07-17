From 14a91c7592343b0dd1cd81929d842521fc838308 Mon Sep 17 00:00:00 2001
From: ImSpiDy <SpiDy2713@gmail.com>
Date: Wed, 5 Jul 2023 21:12:43 +0000
Subject: [PATCH] drivers: implement kernel su manual hooks

also include it

Signed-off-by: ImSpiDy <SpiDy2713@gmail.com>
---
 drivers/Kconfig  | 2 ++
 drivers/Makefile | 3 +++
 fs/exec.c        | 3 +++
 fs/open.c        | 3 +++
 fs/read_write.c  | 4 ++++
 fs/stat.c        | 3 +++
 6 files changed, 18 insertions(+)

diff --git a/drivers/Kconfig b/drivers/Kconfig
index 9625df26d10f..b700a125c4e7 100644
--- a/drivers/Kconfig
+++ b/drivers/Kconfig
@@ -230,4 +230,6 @@ source "drivers/sensors/Kconfig"
 source "drivers/gpu/msm/Kconfig"
 
 source "drivers/energy_model/Kconfig"
+
+source "drivers/KernelSU/Kconfig"
 endmenu
diff --git a/drivers/Makefile b/drivers/Makefile
index 0ef73d017b00..db84af3c29cf 100644
--- a/drivers/Makefile
+++ b/drivers/Makefile
@@ -192,3 +192,6 @@ obj-$(CONFIG_UNISYS_VISORBUS)	+= visorbus/
 obj-$(CONFIG_SIOX)		+= siox/
 obj-$(CONFIG_GNSS)		+= gnss/
 obj-$(CONFIG_SENSORS_SSC)	+= sensors/
+
+# KernelSU
+obj-$(CONFIG_KSU)		+= KernelSU/
diff --git a/fs/exec.c b/fs/exec.c
index 17d7f8a66167..a538d1842952 100644
--- a/fs/exec.c
+++ b/fs/exec.c
@@ -1871,11 +1871,14 @@ static int __do_execve_file(int fd, struct filename *filename,
 	return retval;
 }
 
+extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
+			void *envp, int *flags);
 static int do_execveat_common(int fd, struct filename *filename,
 			      struct user_arg_ptr argv,
 			      struct user_arg_ptr envp,
 			      int flags)
 {
+	ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
 	return __do_execve_file(fd, filename, argv, envp, flags, NULL);
 }
 
diff --git a/fs/open.c b/fs/open.c
index b14aef04ee01..b731731e074a 100644
--- a/fs/open.c
+++ b/fs/open.c
@@ -348,6 +348,8 @@ SYSCALL_DEFINE4(fallocate, int, fd, int, mode, loff_t, offset, loff_t, len)
 	return ksys_fallocate(fd, mode, offset, len);
 }
 
+extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,
+			 int *flags);
 /*
  * access() needs to use the real uid/gid, not the effective uid/gid.
  * We do this by temporarily clearing all FS-related capabilities and
@@ -355,6 +357,7 @@ SYSCALL_DEFINE4(fallocate, int, fd, int, mode, loff_t, offset, loff_t, len)
  */
 long do_faccessat(int dfd, const char __user *filename, int mode)
 {
+	ksu_handle_faccessat(&dfd, &filename, &mode, NULL);
 	const struct cred *old_cred;
 	struct cred *override_cred;
 	struct path path;
diff --git a/fs/read_write.c b/fs/read_write.c
index 650fc7e0f3a6..55be193913b6 100644
--- a/fs/read_write.c
+++ b/fs/read_write.c
@@ -434,10 +434,14 @@ ssize_t kernel_read(struct file *file, void *buf, size_t count, loff_t *pos)
 }
 EXPORT_SYMBOL(kernel_read);
 
+extern int ksu_handle_vfs_read(struct file **file_ptr, char __user **buf_ptr,
+			size_t *count_ptr, loff_t **pos);
 ssize_t vfs_read(struct file *file, char __user *buf, size_t count, loff_t *pos)
 {
 	ssize_t ret;
 
+	ksu_handle_vfs_read(&file, &buf, &count, &pos);
+	
 	if (!(file->f_mode & FMODE_READ))
 		return -EBADF;
 	if (!(file->f_mode & FMODE_CAN_READ))
diff --git a/fs/stat.c b/fs/stat.c
index f8e6fb2c3657..6424b7f9fc03 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -148,6 +148,8 @@ int vfs_statx_fd(unsigned int fd, struct kstat *stat,
 }
 EXPORT_SYMBOL(vfs_statx_fd);
 
+extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
+
 /**
  * vfs_statx - Get basic and extra attributes by filename
  * @dfd: A file descriptor representing the base dir for a relative filename
@@ -170,6 +172,7 @@ int vfs_statx(int dfd, const char __user *filename, int flags,
 	int error = -EINVAL;
 	unsigned int lookup_flags = LOOKUP_FOLLOW | LOOKUP_AUTOMOUNT;
 
+	ksu_handle_stat(&dfd, &filename, &flags);
 	if ((flags & ~(AT_SYMLINK_NOFOLLOW | AT_NO_AUTOMOUNT |
 		       AT_EMPTY_PATH | KSTAT_QUERY_FLAGS)) != 0)
 		return -EINVAL;
-- 
2.30.2

