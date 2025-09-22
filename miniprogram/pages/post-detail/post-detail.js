// pages/post-detail/post-detail.js
const app = getApp()

Page({
  data: {
    postId: null,
    post: null,
    comments: [],
    commentContent: '',
    replyTo: null, // 回复的评论对象
    loading: false,
    commenting: false,
    isLoggedIn: false,
    userInfo: null
  },

  onLoad(options) {
    if (options.id) {
      this.setData({ postId: options.id })
      this.checkLoginStatus()
      this.loadPostDetail()
    } else {
      wx.showToast({
        title: '帖子ID不存在',
        icon: 'none'
      })
      setTimeout(() => {
        wx.navigateBack()
      }, 1500)
    }
  },

  onShow() {
    this.checkLoginStatus()
  },

  // 检查登录状态
  checkLoginStatus() {
    const isLoggedIn = app.isLoggedIn()
    const userInfo = app.globalData.userInfo
    
    this.setData({
      isLoggedIn,
      userInfo
    })
  },

  // 加载帖子详情
  async loadPostDetail() {
    if (this.data.loading) return

    this.setData({ loading: true })

    try {
      const res = await app.request({
        url: `/posts/${this.data.postId}`
      })

      const post = {
        ...res.post,
        formatted_time: app.formatTime(res.post.created_at)
      }

      const comments = res.comments.map(comment => ({
        ...comment,
        formatted_time: app.formatTime(comment.created_at)
      }))

      this.setData({
        post,
        comments,
        loading: false
      })

    } catch (error) {
      console.error('加载帖子详情失败:', error)
      this.setData({ loading: false })
      
      if (error.error === '帖子不存在') {
        wx.showToast({
          title: '帖子不存在',
          icon: 'none'
        })
        setTimeout(() => {
          wx.navigateBack()
        }, 1500)
      }
    }
  },

  // 评论输入
  onCommentInput(e) {
    this.setData({
      commentContent: e.detail.value
    })
  },

  // 提交评论
  async submitComment() {
    if (!this.data.isLoggedIn) {
      wx.showToast({
        title: '请先登录',
        icon: 'none'
      })
      return
    }

    const content = this.data.commentContent.trim()
    if (!content) {
      wx.showToast({
        title: '请输入评论内容',
        icon: 'none'
      })
      return
    }

    this.setData({ commenting: true })

    try {
      const requestData = {
        content
      }

      // 如果是回复评论，添加回复信息
      if (this.data.replyTo) {
        requestData.reply_to_comment_id = this.data.replyTo.id
        requestData.reply_to_user_id = this.data.replyTo.user_id
      }

      const res = await app.request({
        url: `/posts/${this.data.postId}/comments`,
        method: 'POST',
        data: requestData
      })

      // 添加格式化时间
      const newComment = {
        ...res.comment,
        formatted_time: app.formatTime(res.comment.created_at)
      }

      // 将新评论添加到列表末尾
      this.setData({
        comments: [...this.data.comments, newComment],
        commentContent: '',
        replyTo: null,
        commenting: false
      })

      wx.showToast({
        title: '评论成功',
        icon: 'success'
      })

    } catch (error) {
      console.error('发表评论失败:', error)
      this.setData({ commenting: false })
    }
  },

  // 回复评论
  replyToComment(e) {
    if (!this.data.isLoggedIn) {
      wx.showToast({
        title: '请先登录',
        icon: 'none'
      })
      return
    }

    const comment = e.currentTarget.dataset.comment
    this.setData({
      replyTo: comment
    })

    // 滚动到评论输入框
    wx.pageScrollTo({
      selector: '.comment-input',
      duration: 300
    })
  },

  // 取消回复
  cancelReply() {
    this.setData({
      replyTo: null
    })
  },

  // 跳转到登录页
  goToLogin() {
    wx.navigateTo({
      url: '/pages/login/login'
    })
  },

  // 删除帖子
  deletePost() {
    wx.showModal({
      title: '确认删除',
      content: `确定要删除帖子"${this.data.post.title}"吗？删除后无法恢复。`,
      confirmText: '删除',
      confirmColor: '#ff4757',
      success: (res) => {
        if (res.confirm) {
          this.performDelete()
        }
      }
    })
  },

  // 执行删除操作
  async performDelete() {
    wx.showLoading({
      title: '删除中...'
    })

    try {
      await app.request({
        url: `/posts/${this.data.postId}`,
        method: 'DELETE'
      })

      wx.hideLoading()
      wx.showToast({
        title: '删除成功',
        icon: 'success'
      })

      // 返回上一页
      setTimeout(() => {
        wx.navigateBack()
      }, 1500)

    } catch (error) {
      wx.hideLoading()
      console.error('删除帖子失败:', error)
    }
  }
})
