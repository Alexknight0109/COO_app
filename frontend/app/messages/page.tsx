'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { useAuthStore } from '@/lib/store/authStore'
import { messagesApi, Message } from '@/lib/api/messages'
import toast from 'react-hot-toast'
import {
  PaperAirplaneIcon,
  PaperClipIcon,
  PlusIcon,
} from '@heroicons/react/24/outline'
import { format } from 'date-fns'

interface Conversation {
  id: string
  name: string
  lastMessage: string
  time: string
  unread: number
  userId?: string
}

export default function MessagesPage() {
  const { user } = useAuthStore()
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [newMessage, setNewMessage] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      loadConversations()
    }
  }, [user])

  useEffect(() => {
    if (selectedConversation && user) {
      loadMessages(selectedConversation.userId || selectedConversation.id)
    }
  }, [selectedConversation, user])

  const loadConversations = async () => {
    try {
      setLoading(true)
      const allMessages = await messagesApi.getAll(user?.id)
      
      // Group messages by sender/recipient to create conversations
      const conversationMap = new Map<string, Conversation>()
      
      allMessages.forEach((msg) => {
        // Determine the other user in the conversation
        const otherUserId = msg.senderId === user?.id 
          ? (msg.recipients?.[0]?.id || 'unknown')
          : msg.senderId
        
        if (!conversationMap.has(otherUserId)) {
          const otherUser = msg.senderId === user?.id 
            ? msg.recipients?.[0]
            : msg.sender
          
          conversationMap.set(otherUserId, {
            id: otherUserId,
            userId: otherUserId,
            name: otherUser 
              ? `${otherUser.firstName} ${otherUser.lastName}`
              : 'Unknown User',
            lastMessage: msg.content,
            time: format(new Date(msg.createdAt), 'MMM d, h:mm a'),
            unread: msg.isRead ? 0 : 1,
          })
        } else {
          const conv = conversationMap.get(otherUserId)!
          // Update if this message is more recent
          if (new Date(msg.createdAt) > new Date(conv.time)) {
            conv.lastMessage = msg.content
            conv.time = format(new Date(msg.createdAt), 'MMM d, h:mm a')
            if (!msg.isRead) conv.unread++
          }
        }
      })

      setConversations(Array.from(conversationMap.values()))
      if (conversations.length > 0 && !selectedConversation) {
        setSelectedConversation(conversations[0])
      }
    } catch (error) {
      console.error('Failed to load conversations:', error)
      toast.error('Failed to load conversations')
    } finally {
      setLoading(false)
    }
  }

  const loadMessages = async (otherUserId: string) => {
    try {
      const conversationMessages = await messagesApi.getConversation(otherUserId, user?.id)
      setMessages(conversationMessages.sort((a, b) => 
        new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
      ))
    } catch (error) {
      console.error('Failed to load messages:', error)
      toast.error('Failed to load messages')
    }
  }

  const handleSend = async () => {
    if (!newMessage.trim() || !selectedConversation || !user) return

    try {
      const message = await messagesApi.create({
        content: newMessage,
        recipientIds: [selectedConversation.userId || selectedConversation.id],
        type: 'DM',
      })
      
      setMessages([...messages, message])
      setNewMessage('')
      toast.success('Message sent')
      
      // Reload conversations to update last message
      loadConversations()
    } catch (error) {
      console.error('Failed to send message:', error)
      toast.error('Failed to send message')
    }
  }

  const formatMessageTime = (date: string) => {
    return format(new Date(date), 'h:mm a')
  }

  const isSentByMe = (message: Message) => {
    return message.senderId === user?.id
  }

  const getSenderName = (message: Message) => {
    if (message.sender) {
      return `${message.sender.firstName} ${message.sender.lastName}`
    }
    return 'Unknown'
  }

  return (
    <ProtectedRoute>
      <div className="flex min-h-screen">
        <Sidebar />
        <div className="flex-1 ml-64">
          <Header />
          <main className="p-6 h-[calc(100vh-80px)]">
            <div className="mb-6">
              <h1 className="text-3xl font-bold text-[var(--text-primary)] mb-2">
                Messages
              </h1>
              <p className="text-[var(--text-secondary)]">
                Communicate with your team
              </p>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
              </div>
            ) : (
              <div className="flex gap-4 h-[calc(100vh-200px)]">
                {/* Conversations List */}
                <div className="w-80">
                  <Card className="h-full overflow-hidden flex flex-col">
                    <div className="flex items-center justify-between mb-4">
                      <h2 className="font-semibold text-[var(--text-primary)]">
                        Conversations
                      </h2>
                      <button className="p-2 rounded-lg hover:bg-[var(--hover-bg)]">
                        <PlusIcon className="w-5 h-5" />
                      </button>
                    </div>

                    <div className="flex-1 overflow-y-auto space-y-2">
                      {conversations.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">
                          No conversations yet
                        </p>
                      ) : (
                        conversations.map((conv) => (
                          <button
                            key={conv.id}
                            onClick={() => setSelectedConversation(conv)}
                            className={`w-full p-3 rounded-lg text-left transition-colors ${
                              selectedConversation?.id === conv.id
                                ? 'bg-gradient-purple-blue/20 border border-purple-500/50'
                                : 'hover:bg-[var(--hover-bg)] border border-transparent'
                            }`}
                          >
                            <div className="flex items-center justify-between mb-1">
                              <h3 className="font-medium text-[var(--text-primary)]">
                                {conv.name}
                              </h3>
                              {conv.unread > 0 && (
                                <span className="w-5 h-5 bg-purple-500 text-white text-xs rounded-full flex items-center justify-center">
                                  {conv.unread}
                                </span>
                              )}
                            </div>
                            <p className="text-sm text-[var(--text-secondary)] truncate">
                              {conv.lastMessage}
                            </p>
                            <p className="text-xs text-[var(--text-secondary)] mt-1">
                              {conv.time}
                            </p>
                          </button>
                        ))
                      )}
                    </div>
                  </Card>
                </div>

                {/* Chat Area */}
                <div className="flex-1">
                  <Card className="h-full flex flex-col">
                    {selectedConversation ? (
                      <>
                        {/* Chat Header */}
                        <div className="border-b border-[var(--border-color)] pb-4 mb-4">
                          <h2 className="font-semibold text-[var(--text-primary)]">
                            {selectedConversation.name}
                          </h2>
                          <p className="text-sm text-[var(--text-secondary)]">
                            Online
                          </p>
                        </div>

                        {/* Messages */}
                        <div className="flex-1 overflow-y-auto space-y-4 mb-4">
                          {messages.length === 0 ? (
                            <p className="text-[var(--text-secondary)] text-center py-8">
                              No messages yet. Start the conversation!
                            </p>
                          ) : (
                            messages.map((msg) => {
                              const sent = isSentByMe(msg)
                              return (
                                <div
                                  key={msg.id}
                                  className={`flex ${sent ? 'justify-end' : 'justify-start'}`}
                                >
                                  <div
                                    className={`message-bubble ${
                                      sent ? 'message-sent' : 'message-received'
                                    }`}
                                  >
                                    {!sent && (
                                      <p className="text-xs opacity-70 mb-1">
                                        {getSenderName(msg)}
                                      </p>
                                    )}
                                    <p className="mb-1">{msg.content}</p>
                                    <p className="text-xs opacity-70">
                                      {formatMessageTime(msg.createdAt)}
                                    </p>
                                  </div>
                                </div>
                              )
                            })
                          )}
                        </div>

                        {/* Message Input */}
                        <div className="flex items-center gap-2 pt-4 border-t border-[var(--border-color)]">
                          <button className="p-2 rounded-lg hover:bg-[var(--hover-bg)]">
                            <PaperClipIcon className="w-5 h-5 text-[var(--text-secondary)]" />
                          </button>
                          <input
                            type="text"
                            value={newMessage}
                            onChange={(e) => setNewMessage(e.target.value)}
                            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
                            placeholder="Type a message..."
                            className="flex-1 px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] focus:outline-none focus:border-purple-500"
                          />
                          <button
                            onClick={handleSend}
                            className="p-2 rounded-lg gradient-purple-blue hover:shadow-glow transition-all"
                          >
                            <PaperAirplaneIcon className="w-5 h-5 text-white" />
                          </button>
                        </div>
                      </>
                    ) : (
                      <div className="flex-1 flex items-center justify-center">
                        <p className="text-[var(--text-secondary)]">
                          Select a conversation to start messaging
                        </p>
                      </div>
                    )}
                  </Card>
                </div>
              </div>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}
